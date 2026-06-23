import SwiftUI

struct ContentView: View {
    @StateObject private var appState: AppState
    @State private var selectedTab: AppTab
    @State private var showingNotifications: Bool
    @State private var shouldOpenKYC = false
    @State private var passwordResetToken: String?

    init() {
        let args = ProcessInfo.processInfo.arguments
        _appState = StateObject(wrappedValue: AppState())
        if let index = args.firstIndex(of: "--tab"), args.indices.contains(index + 1),
           let tab = AppTab(rawValue: args[index + 1].capitalized) {
            _selectedTab = State(initialValue: tab)
        } else {
            _selectedTab = State(initialValue: .home)
        }
        _showingNotifications = State(initialValue: args.contains("--notifications"))
    }

    var body: some View {
        Group {
            if appState.isCheckingSession {
                ProgressView("Connecting to Limu…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(LimuColors.ink)
            } else if appState.isAuthenticated {
                mainApp
            } else {
                AuthenticationView(resetLinkToken: $passwordResetToken) {
                    selectedTab = .home
                }
            }
        }
        .environmentObject(appState)
        .environment(\.font, .limu(size: 14))
        .background(LimuColors.cream)
        .tint(LimuColors.copper)
        .preferredColorScheme(.dark)
        .task { await appState.bootstrap() }
        .onOpenURL(perform: handleDeepLink)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            handleDeepLink(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .limuDidRegisterForRemoteNotifications)) { notification in
            guard let token = notification.userInfo?["token"] as? String else { return }
            Task { await appState.savePushToken(token) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .limuRemoteNotificationReceived)) { _ in
            Task { await appState.refreshAfterRemoteNotification() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .limuRemoteNotificationTapped)) { notification in
            handleRemoteNotificationTap(notification)
        }
        .alert("Limu", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "Something went wrong.")
        }
    }

    private var mainApp: some View {
        Group {
            if showingNotifications {
                NotificationsView(
                    notifications: $appState.notifications,
                    onBack: { showingNotifications = false },
                    onNavigate: navigate
                )
            } else {
                TabView(selection: guardedTabSelection) {
                    Tab("Home", systemImage: AppTab.home.icon, value: AppTab.home) {
                        HomeView(
                            unreadCount: appState.unreadCount,
                            notifications: appState.notifications,
                            onNavigate: navigate,
                            onNotifications: { showingNotifications = true }
                        )
                    }
                    Tab("Cargo", systemImage: AppTab.cargo.icon, value: AppTab.cargo) {
                        CargoView()
                    }
                    Tab("Shipments", systemImage: AppTab.shipments.icon, value: AppTab.shipments) {
                        ShipmentsView()
                    }
                    Tab("Invoices", systemImage: AppTab.invoices.icon, value: AppTab.invoices) {
                        InvoicesView()
                    }
                    Tab("Profile", systemImage: AppTab.profile.icon, value: AppTab.profile) {
                        ProfileView(shouldOpenKYC: $shouldOpenKYC) {
                            Task {
                                await appState.logout()
                                await MainActor.run { selectedTab = .home }
                            }
                        }
                    }
                    .badge(appState.unreadCount)
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .tint(LimuColors.sunsetOrange)
            }
        }
        .background(LimuColors.cream)
    }

    private var guardedTabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { navigate($0) }
        )
    }

    private func navigate(_ tab: AppTab) {
        showingNotifications = false
        selectedTab = tab
    }

    private func openKYC() {
        showingNotifications = false
        shouldOpenKYC = true
        selectedTab = .profile
    }

    private func handleDeepLink(_ url: URL) {
        guard let token = Self.passwordResetToken(from: url) else { return }
        showingNotifications = false
        selectedTab = .home
        appState.beginPasswordResetFromLink()
        passwordResetToken = token
    }

    private func handleRemoteNotificationTap(_ notification: Notification) {
        Task { await appState.refreshAfterRemoteNotification() }
        guard appState.isAuthenticated else { return }
        if let destination = Self.notificationDestination(from: notification) {
            navigate(destination)
        } else {
            showingNotifications = true
        }
    }

    private static func notificationDestination(from notification: Notification) -> AppTab? {
        guard let userInfo = notification.userInfo else { return nil }
        let rawDestination = (userInfo["destination"] as? String)
            ?? (userInfo["tab"] as? String)
            ?? (userInfo["objectType"] as? String)
        guard let rawDestination else { return nil }
        switch rawDestination.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "cargo":
            return .cargo
        case "shipment", "shipments":
            return .shipments
        case "invoice", "invoices", "payment":
            return .invoices
        case "profile", "kyc":
            return .profile
        case "home", "notifications":
            return .home
        default:
            return nil
        }
    }

    private static func passwordResetToken(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        let queryItems = components.queryItems ?? []
        let purpose = queryItems.first { $0.name.caseInsensitiveCompare("purpose") == .orderedSame }?.value?.lowercased()
        guard let token = queryItems.first(where: { $0.name.caseInsensitiveCompare("token") == .orderedSame })?.value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            return nil
        }

        let scheme = components.scheme?.lowercased()
        let host = components.host?.lowercased() ?? ""
        let path = components.path.lowercased()
        let isLimuResetLink = scheme == "limu"
            && (host == "reset-password" || path.contains("reset-password") || purpose == "password_reset")
        let isUniversalResetLink = ["http", "https"].contains(scheme ?? "")
            && (path.contains("/reset-password") || path.contains("/mobile/account") || purpose == "password_reset")

        return (isLimuResetLink || isUniversalResetLink) ? token : nil
    }
}

private struct KYCRestrictedView: View {
    let feature: String
    let onCompleteKYC: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AppHeader {
                Text(feature)
                    .font(.limu(size: 18, weight: .bold))
            }
            VStack(spacing: 16) {
                BrandEmptyStateIcon(systemName: "lock.shield", symbolSize: 40)
                Text("Complete KYC to access \(feature)")
                    .font(.limu(size: 18, weight: .bold))
                    .foregroundStyle(LimuColors.ink)
                    .multilineTextAlignment(.center)
                Text("Add your KYC details once to unlock your logistics information immediately.")
                    .font(.limu(size: 13))
                    .foregroundStyle(LimuColors.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                PrimaryButton(title: "Complete KYC", action: onCompleteKYC)
                    .frame(maxWidth: 240)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(LimuColors.cream.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
