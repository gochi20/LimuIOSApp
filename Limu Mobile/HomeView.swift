import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    let unreadCount: Int
    let notifications: [AppNotification]
    let onNavigate: (AppTab) -> Void
    let onNotifications: () -> Void

    private var activeCargo: [Cargo] { appState.cargo.filter { !["Collected", "Completed"].contains($0.status) } }
    private var pendingBalance: Double { appState.invoices.filter { $0.status != "Paid" }.reduce(0) { $0 + $1.balance } }
    private var defaultCurrency: String {
        LimuCurrency.code(appState.dashboard?.metrics.currency ?? appState.invoices.first?.currency)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                metrics
                homeSection("Active Cargo", seeAll: { onNavigate(.cargo) }) {
                    ForEach(activeCargo) { cargo in
                        Button { onNavigate(.cargo) } label: { cargoPreview(cargo) }
                            .buttonStyle(.plain)
                    }
                }
                if let shipment = appState.shipments.first(where: { $0.status == "In Transit" }) ?? appState.shipments.first {
                    homeSection("Shipment Update", seeAll: { onNavigate(.shipments) }) {
                        Button { onNavigate(.shipments) } label: { shipmentPreview(shipment) }
                            .buttonStyle(.plain)
                    }
                }
                homeSection("Invoices", seeAll: { onNavigate(.invoices) }) {
                    ForEach(appState.invoices.prefix(2)) { invoice in
                        Button { onNavigate(.invoices) } label: { invoicePreview(invoice) }
                            .buttonStyle(.plain)
                    }
                }
                homeSection("Notifications", seeAll: onNotifications) {
                    ForEach(notifications.filter(\.isUnread).prefix(2)) { notification in
                        notificationPreview(notification)
                    }
                }
                Color.clear.frame(height: 24)
            }
        }
        .background(LimuColors.cream)
        .ignoresSafeArea(edges: .top)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                LimuEmblemMark(size: 54)
                Spacer()
                Button(action: onNotifications) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.limu(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        if unreadCount > 0 {
                            Circle().fill(LimuColors.copper).frame(width: 8, height: 8)
                                .overlay { Circle().stroke(LimuColors.charcoal, lineWidth: 1.5) }
                                .offset(x: -5, y: 5)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notifications")
            }
            .padding(.bottom, 16)

            Text("Good morning")
                .font(.limu(size: 11))
                .foregroundStyle(LimuColors.peach)
            Text(profileTitle)
                .font(.limu(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 1)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 58)
        .padding(.bottom, 28)
        .background { BrandHeaderBackdrop() }
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            metricCard(icon: "shippingbox.fill", tint: LimuColors.copperWash, value: "\(appState.dashboard?.metrics.activeCargoCount ?? activeCargo.count)", label: "Active Cargo") { onNavigate(.cargo) }
            metricCard(icon: "storefront.fill", tint: LimuColors.successWash, value: "\(appState.dashboard?.metrics.readyForCollectionCount ?? appState.cargo.filter(\.readyForCollection).count)", label: "For Collection") { onNavigate(.cargo) }
            metricCard(icon: "creditcard.fill", tint: LimuColors.dangerWash, value: MockData.money(pendingBalance, currency: defaultCurrency), label: "Balance Due") { onNavigate(.invoices) }
        }
        .padding(.horizontal, 16)
        .offset(y: -14)
        .padding(.bottom, -14)
    }

    private var profileTitle: String {
        guard let profile = appState.profile else { return "Limu Client" }
        if !profile.businessName.isEmpty { return "\(profile.firstName) · \(profile.businessName)" }
        return profile.fullName
    }

    private func metricCard(icon: String, tint: Color, value: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LimuCard(padding: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    BrandCircleSymbol(systemName: icon, diameter: 32, symbolSize: 14)
                        .background(tint)
                        .clipShape(Circle())
                        .padding(.bottom, 8)
                    Text(value)
                        .font(.limu(size: value.count > 4 ? 15 : 16, weight: .heavy))
                        .foregroundStyle(LimuColors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(label)
                        .font(.limu(size: 10, weight: .semibold))
                        .foregroundStyle(LimuColors.secondary)
                        .padding(.top, 3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func homeSection<Content: View>(_ title: String, seeAll: @escaping () -> Void, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.limu(size: 13, weight: .bold))
                    .foregroundStyle(LimuColors.ink)
                Spacer()
                Button("See all", action: seeAll)
                    .font(.limu(size: 12, weight: .semibold))
                    .foregroundStyle(LimuColors.copper)
                    .buttonStyle(.plain)
            }
            VStack(spacing: 8) { content() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    private func cargoPreview(_ cargo: Cargo) -> some View {
        LimuCard(padding: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cargo.id).font(.limu(size: 13, weight: .bold)).foregroundStyle(LimuColors.ink)
                    Text(cargo.summary).font(.limu(size: 11)).foregroundStyle(LimuColors.secondary)
                }
                Spacer()
                StatusBadge(status: cargo.status)
            }
            HStack(spacing: 12) {
                IconText(icon: "mappin", text: cargo.location)
                Spacer(minLength: 2)
                IconText(icon: "shippingbox", text: "\(cargo.packages) pkgs")
                IconText(icon: "scalemass", text: "\(cargo.weight.formatted()) kg")
            }
            .padding(.top, 10)
            HStack {
                Text("Finance:").font(.limu(size: 11)).foregroundStyle(LimuColors.secondary)
                Spacer()
                StatusBadge(status: cargo.financeStatus)
            }
            .padding(.top, 8)
            .overlay(alignment: .top) { Rectangle().fill(LimuColors.softCream).frame(height: 1) }
        }
    }

    private func shipmentPreview(_ shipment: Shipment) -> some View {
        LimuCard(padding: 16) {
            HStack {
                Text(shipment.name).font(.limu(size: 13, weight: .bold)).foregroundStyle(LimuColors.ink)
                Spacer()
                StatusBadge(status: shipment.status)
            }
            HStack(spacing: 12) {
                IconText(icon: "ferry", text: shipment.mode)
                IconText(icon: "mappin", text: shipment.location)
            }
            .padding(.vertical, 10)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEPARTED").font(.limu(size: 10, weight: .semibold)).foregroundStyle(LimuColors.muted)
                    Text(shipment.departure).font(.limu(size: 12, weight: .bold))
                }
                HStack(spacing: 0) {
                    Capsule().fill(LimuColors.copper).frame(height: 2)
                    Circle().fill(LimuColors.copper).frame(width: 8, height: 8)
                    Capsule().fill(LimuColors.peach).frame(height: 2)
                }
                .padding(.horizontal, 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ETA").font(.limu(size: 10, weight: .semibold)).foregroundStyle(LimuColors.muted)
                    Text(shipment.arrival).font(.limu(size: 12, weight: .bold))
                }
            }
            .foregroundStyle(LimuColors.ink)
            .padding(10)
            .background(LimuColors.softCream)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func invoicePreview(_ invoice: Invoice) -> some View {
        LimuCard(padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(invoice.id).font(.limu(size: 13, weight: .bold)).foregroundStyle(LimuColors.ink)
                    Text("\(invoice.date) · \(invoice.currency)").font(.limu(size: 11)).foregroundStyle(LimuColors.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(MockData.money(invoice.balance, currency: invoice.currency))
                        .font(.limu(size: 15, weight: .bold))
                        .foregroundStyle(invoice.balance > 0 ? LimuColors.danger : LimuColors.success)
                    StatusBadge(status: invoice.status)
                }
            }
        }
    }

    private func notificationPreview(_ notification: AppNotification) -> some View {
        LimuCard(padding: 14) {
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(LimuColors.copper).frame(width: 8, height: 8).padding(.top, 4)
                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title).font(.limu(size: 12, weight: .bold)).foregroundStyle(LimuColors.ink)
                    Text(notification.message).font(.limu(size: 11)).foregroundStyle(LimuColors.secondary).lineSpacing(2)
                    Text(notification.timestamp).font(.limu(size: 10)).foregroundStyle(LimuColors.muted)
                }
            }
        }
        .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(LimuColors.copper).frame(width: 3).padding(.vertical, 2) }
    }
}
