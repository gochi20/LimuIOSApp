import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isCheckingSession = true
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var lastErrorCode: String?
    @Published var profile: ProfileDTO?
    @Published var dashboard: DashboardDTO?
    @Published var cargo: [Cargo] = []
    @Published var shipments: [Shipment] = []
    @Published var invoices: [Invoice] = []
    @Published var notifications: [AppNotification] = []
    @Published private var demoKYCCompleted = false

    private let api = APIClient.shared
    private let demoMode: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        demoMode = arguments.contains("--logged-in")
        if demoMode {
            demoKYCCompleted = arguments.contains("--kyc-complete")
            isAuthenticated = true
            isCheckingSession = false
            cargo = MockData.cargo
            shipments = MockData.shipments
            invoices = MockData.invoices
            let demoNotifications = MockData.notifications
            notifications = demoKYCCompleted
                ? demoNotifications
                : demoNotifications.filter { !$0.destination.requiresCompletedKYC }
        }
    }

    var unreadCount: Int { notifications.filter(\.isUnread).count }

    var kycStatus: String {
        dashboard?.metrics.kycStatus
            ?? profile?.kycStatus
            ?? (demoMode && demoKYCCompleted ? "Completed" : "Incomplete")
    }

    var hasCompletedKYC: Bool {
        Self.hasCompletedKYC(status: kycStatus)
    }

    var clientType: String {
        if let value = profile?.clientType, !value.isEmpty { return value }
        return ProcessInfo.processInfo.arguments.contains("--personal-account") ? "Personal" : "Business"
    }

    func bootstrap() async {
        guard !demoMode else { return }
        guard APIClient.hasStoredSession else {
            isCheckingSession = false
            return
        }
        do {
            try await refreshAll()
            isAuthenticated = true
        } catch {
            api.clearSession()
            isAuthenticated = false
        }
        isCheckingSession = false
    }

    func login(identifier: String, password: String, stayLoggedIn: Bool) async -> Bool {
        return await runBusy {
            let payload: AuthPayloadDTO = try await api.post(
                "auth/login.php",
                body: ["identifier": identifier, "password": password, "deviceId": deviceID],
                authenticated: false
            )
            api.store(payload.session, persist: stayLoggedIn)
            profile = payload.client
            do { try await refreshAll() }
            catch { api.clearSession(); throw error }
            isAuthenticated = true
        }
    }

    func register(firstName: String, lastName: String, email: String, phone: String, password: String, clientType: String, businessName: String, location: String) async -> RegistrationPayloadDTO? {
        var registration: RegistrationPayloadDTO?
        let success = await runBusy {
            var body: [String: Any] = [
                "firstName": firstName, "lastName": lastName, "email": email,
                "phone": phone, "password": password, "clientType": clientType,
                "location": location, "deviceId": deviceID
            ]
            if !businessName.isEmpty { body["businessName"] = businessName }
            registration = try await api.post("auth/register.php", body: body, authenticated: false)
        }
        return success ? registration : nil
    }

    func verifyRegistrationEmail(identifier: String, code: String) async -> Bool {
        await runBusy {
            let payload: AuthPayloadDTO = try await api.post(
                "auth/verify-email.php",
                body: ["identifier": identifier, "code": code, "deviceId": deviceID],
                authenticated: false
            )
            api.store(payload.session, persist: true)
            profile = payload.client
            do { try await refreshAll() }
            catch { api.clearSession(); throw error }
            isAuthenticated = true
        }
    }

    func resendRegistrationVerification(identifier: String) async -> Bool {
        await runBusy {
            try await api.send(
                "auth/resend-verification.php",
                body: ["identifier": identifier],
                authenticated: false
            )
        }
    }

    func clearError() {
        errorMessage = nil
        lastErrorCode = nil
    }

    func beginPasswordResetFromLink() {
        api.clearSession()
        isAuthenticated = false
        isCheckingSession = false
        profile = nil
        dashboard = nil
        cargo = []
        shipments = []
        invoices = []
        notifications = []
        clearError()
    }

    func requestPasswordReset(identifier: String) async -> Bool {
        await runBusy {
            try await api.send("auth/forgot-password.php", body: ["identifier": identifier], authenticated: false)
        }
    }

    func completePasswordReset(token: String, password: String) async -> Bool {
        await runBusy {
            try await api.send("auth/reset-password.php", body: ["token": token, "password": password], authenticated: false)
        }
    }

    func requestAccountClaim(identifier: String) async -> Bool {
        await runBusy {
            try await api.send("auth/claim/request.php", body: ["identifier": identifier], authenticated: false)
        }
    }

    func completeAccountClaim(token: String, password: String) async -> Bool {
        await runBusy {
            try await api.send("auth/claim/complete.php", body: ["token": token, "password": password], authenticated: false)
        }
    }

    func logout() async {
        if !demoMode { try? await api.send("auth/logout.php", body: ["allSessions": false]) }
        api.clearSession()
        isAuthenticated = false
        profile = nil
        dashboard = nil
        cargo = []
        shipments = []
        invoices = []
        notifications = []
    }

    func refreshAll() async throws {
        let dashboardDTO: DashboardDTO = try await api.get("dashboard.php")
        let canViewLogistics = Self.hasCompletedKYC(status: dashboardDTO.metrics.kycStatus)
        let cargoDTOs: [CargoDTO] = canViewLogistics
            ? try await api.get("cargo/index.php", query: [URLQueryItem(name: "perPage", value: "100")])
            : []
        let shipmentDTOs: [ShipmentDTO] = canViewLogistics
            ? try await api.get("shipments/index.php", query: [URLQueryItem(name: "perPage", value: "100")])
            : []
        let invoiceDTOs: [InvoiceDTO] = try await api.get("invoices/index.php", query: [URLQueryItem(name: "perPage", value: "100")])
        let notificationDTOs: [NotificationDTO] = try await api.get("notifications/index.php", query: [URLQueryItem(name: "limit", value: "100")])
        dashboard = dashboardDTO
        profile = dashboardDTO.client
        cargo = cargoDTOs.map(\.model)
        shipments = shipmentDTOs.map(\.model)
        invoices = invoiceDTOs.map(\.model)
        notifications = notificationDTOs.map(\.model)
    }

    func fetchCargoDetail(_ id: Int) async throws -> (Cargo, [CargoPackage], [TimelineEvent]) {
        if demoMode, let cargo = cargo.first(where: { $0.apiID == id || id == 0 }) {
            return (cargo, MockData.packages, MockData.cargoTimeline)
        }
        let dto: CargoDTO = try await api.get("cargo/show.php", query: [URLQueryItem(name: "id", value: String(id))])
        return (dto.model, (dto.packages ?? []).map(\.model), (dto.timeline ?? []).map(\.model))
    }

    func fetchShipmentDetail(_ id: Int) async throws -> (Shipment, [ShipmentUpdate], [Cargo]) {
        if demoMode, let shipment = shipments.first(where: { $0.apiID == id || id == 0 }) {
            return (shipment, MockData.shipmentUpdates.filter { $0.shipmentID == shipment.id }, cargo)
        }
        let dto: ShipmentDTO = try await api.get("shipments/show.php", query: [URLQueryItem(name: "id", value: String(id))])
        let shipment = dto.model
        return (shipment, (dto.updates ?? []).map { $0.model(shipmentID: shipment.id, location: shipment.location) }, (dto.cargo ?? []).map(\.model))
    }

    func fetchInvoiceDetail(_ id: Int) async throws -> Invoice {
        if demoMode { return invoices.first(where: { $0.apiID == id || id == 0 }) ?? MockData.invoices[0] }
        let dto: InvoiceDTO = try await api.get("invoices/show.php", query: [URLQueryItem(name: "id", value: String(id))])
        return dto.model
    }

    func markRead(_ notification: AppNotification) async {
        guard notification.isUnread else { return }
        if !demoMode { try? await api.send("notifications/read.php", method: "PATCH", body: ["id": notification.id]) }
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) { notifications[index].isUnread = false }
    }

    func markAllRead() async {
        if !demoMode { try? await api.send("notifications/read-all.php") }
        for index in notifications.indices { notifications[index].isUnread = false }
    }

    func updateProfile(_ values: [String: Any]) async -> Bool {
        await runBusy {
            let updated: ProfileDTO = try await api.patch("profile/index.php", body: values)
            profile = updated
            dashboard = nil
        }
    }

    func changePassword(current: String, new: String) async -> Bool {
        let success = await runBusy {
            try await api.send("profile/password.php", method: "PATCH", body: ["currentPassword": current, "newPassword": new])
        }
        if success {
            api.clearSession()
            isAuthenticated = false
        }
        return success
    }

    func loadKYC() async throws -> KYCRecordDTO { try await api.get("kyc/index.php") }

    func loadCategories(query: String = "") async throws -> [CategoryDTO] {
        if demoMode {
            let categories = [
                CategoryDTO(id: 3, name: "Assorted"),
                CategoryDTO(id: 2, name: "Electronics"),
                CategoryDTO(id: 1, name: "Spare parts")
            ]
            let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
            return search.isEmpty ? categories : categories.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        return try await api.get(
            "categories/get.php",
            query: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "12" : "50")
            ]
        )
    }

    func saveKYC(_ values: [String: Any], submit: Bool) async -> Bool {
        if demoMode {
            if submit { demoKYCCompleted = true }
            return true
        }
        return await runBusy {
            let _: KYCRecordDTO
            if submit {
                let value: KYCRecordDTO = try await api.post("kyc/submit.php", body: values)
                _ = value
                try await refreshAll()
            } else {
                let value: KYCRecordDTO = try await api.put("kyc/index.php", body: values)
                _ = value
            }
        }
    }

    private static func hasCompletedKYC(status: String) -> Bool {
        status.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("Completed") == .orderedSame
    }

    func uploadPayment(invoiceID: Int, amount: Double, transactionID: String, notes: String, fileURL: URL) async -> Bool {
        await runBusy {
            let _: PaymentDTO = try await api.uploadPaymentProof(invoiceID: invoiceID, amount: amount, transactionID: transactionID, notes: notes, fileURL: fileURL)
            try await refreshAll()
        }
    }

    private func runBusy(_ operation: () async throws -> Void) async -> Bool {
        isBusy = true
        errorMessage = nil
        lastErrorCode = nil
        defer { isBusy = false }
        do {
            try await operation()
            return true
        } catch {
            lastErrorCode = (error as? APIError)?.code
            errorMessage = error.localizedDescription
            return false
        }
    }

    private var deviceID: String {
        if let value = UserDefaults.standard.string(forKey: "limuDeviceID") { return value }
        let value = UUID().uuidString
        UserDefaults.standard.set(value, forKey: "limuDeviceID")
        return value
    }
}
