import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var notifications: [AppNotification]
    let onBack: () -> Void
    let onNavigate: (AppTab) -> Void

    private var unreadCount: Int { notifications.filter(\.isUnread).count }

    var body: some View {
        VStack(spacing: 0) {
            AppHeader {
                HStack(spacing: 10) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.limu(size: 14, weight: .bold))
                            .foregroundStyle(LimuColors.peach)
                    }
                    .buttonStyle(.plain)
                    Text("Notifications")
                        .font(.limu(size: 18, weight: .bold))
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.limu(size: 11, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(LimuColors.copper)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    if unreadCount > 0 {
                        Button("Mark all read") {
                            Task { await appState.markAllRead() }
                        }
                        .font(.limu(size: 12, weight: .semibold))
                        .foregroundStyle(LimuColors.peach)
                        .buttonStyle(.plain)
                    }
                }
            }

            if notifications.isEmpty {
                VStack(spacing: 12) {
                    BrandEmptyStateIcon(systemName: "bell.slash", symbolSize: 42)
                    Text("No Notifications").font(.limu(size: 15, weight: .bold))
                    Text("You're all caught up!").font(.limu(size: 13)).foregroundStyle(LimuColors.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(notifications) { notification in
                            Button { open(notification) } label: { notificationCard(notification) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(LimuColors.cream.ignoresSafeArea())
    }

    private func open(_ notification: AppNotification) {
        Task { await appState.markRead(notification) }
        onNavigate(notification.destination)
    }

    private func notificationCard(_ notification: AppNotification) -> some View {
        LimuCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon(for: notification.category))
                    .font(.limu(size: 17, weight: .semibold))
                    .foregroundStyle(LimuColors.copper)
                    .frame(width: 38, height: 38)
                    .background(categoryBackground(notification.category))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top) {
                        Text(notification.title)
                            .font(.limu(size: 13, weight: notification.isUnread ? .bold : .semibold))
                            .foregroundStyle(LimuColors.ink)
                        Spacer(minLength: 8)
                        if notification.isUnread { Circle().fill(LimuColors.copper).frame(width: 8, height: 8).padding(.top, 3) }
                    }
                    Text(notification.message)
                        .font(.limu(size: 12))
                        .foregroundStyle(LimuColors.secondary)
                        .lineSpacing(2)
                    HStack {
                        Text(notification.timestamp).font(.limu(size: 10)).foregroundStyle(LimuColors.muted)
                        Spacer()
                        Text(notification.category)
                            .font(.limu(size: 10, weight: .bold))
                            .foregroundStyle(LimuColors.copper)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryBackground(notification.category))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .opacity(notification.isUnread ? 1 : 0.82)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(notification.isUnread ? LimuColors.copper : .clear).frame(width: 3).padding(.vertical, 2)
        }
    }

    private func icon(for category: String) -> String {
        switch category {
        case "Cargo": "shippingbox.fill"
        case "Invoice": "doc.text.fill"
        case "Payment": "creditcard.fill"
        case "Shipment": "ferry.fill"
        case "KYC": "checklist.checked"
        default: "gearshape.fill"
        }
    }

    private func categoryBackground(_ category: String) -> Color {
        switch category {
        case "Payment": LimuColors.successWash
        case "Invoice": LimuColors.dangerWash
        default: LimuColors.copperWash
        }
    }
}
