import Foundation

struct AuthPayloadDTO: Decodable {
    let client: ProfileDTO
    let session: SessionDTO
}

struct RegistrationPayloadDTO: Decodable {
    let verificationRequired: Bool
    let email: String
    let emailSent: Bool
    let expiresAt: String
    let testCode: String?
}

struct SessionDTO: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresAt: String
    let refreshExpiresAt: String
}

struct ProfileDTO: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let fullName: String
    let email: String
    let phone: String
    let clientType: String
    let businessName: String
    let businessCategory: String
    let location: String
    let customerCategory: String?
    let shipmentCount: Int
    let lastShipmentDate: String?
    let photoUrl: String?
    let gender: String?
    let dateOfBirth: String?
    let occupations: [String]?
    let interests: [String]?
    let alternatePhones: [String]?
    let kycStatus: String?
}

struct DashboardDTO: Decodable {
    let greetingName: String
    let client: ProfileDTO
    let metrics: DashboardMetricsDTO
    let activeCargo: [CargoDTO]
    let shipments: [ShipmentDTO]
    let invoices: [InvoiceDTO]
    let notifications: [NotificationDTO]
}

struct DashboardMetricsDTO: Decodable {
    let activeCargoCount: Int
    let readyForCollectionCount: Int
    let balanceDue: Double
    let currency: String
    let unreadNotificationCount: Int
    let kycStatus: String
}

struct CargoDTO: Decodable {
    let id: Int
    let trackingNumber: String
    let status: String
    let contentSummary: String
    let packageCount: Int
    let checkedPackageCount: Int
    let weightKg: Double
    let volumeCbm: Double
    let currentLocation: String
    let financeStatus: String
    let shipmentId: Int?
    let shipmentName: String
    let createdAt: String?
    let readyForCollection: Bool
    let collectionLocation: String?
    let notes: String?
    let consignmentValue: Double
    let packages: [CargoPackageDTO]?
    let timeline: [TimelineDTO]?
    let invoice: CargoInvoiceDTO?

    var model: Cargo {
        Cargo(
            apiID: id,
            id: trackingNumber.isEmpty ? "CGO-\(id)" : trackingNumber,
            status: status,
            summary: contentSummary,
            packages: packageCount,
            weight: weightKg,
            volume: volumeCbm,
            location: currentLocation,
            financeStatus: financeStatus,
            shipmentName: shipmentName,
            createdAt: createdAt ?? "—",
            readyForCollection: readyForCollection,
            collectionLocation: collectionLocation,
            notes: notes,
            checkedPackages: checkedPackageCount,
            invoiceAPIID: invoice?.id
        )
    }
}

struct CargoInvoiceDTO: Decodable {
    let id: Int
    let status: String
    let total: Double
    let balance: Double
    let currency: String
}

struct CargoPackageDTO: Decodable {
    let id: Int
    let cargoId: Int
    let code: String
    let content: String
    let quantity: Int
    let packageType: String
    let declaredValue: Double
    let courierTrackingNumber: String
    let imageUrl: String?
    let checked: Bool
    let checkedAt: String?
    let createdAt: String?

    var model: CargoPackage {
        CargoPackage(
            id: String(id),
            content: content,
            quantity: quantity,
            type: packageType,
            code: code,
            courierTracking: courierTrackingNumber,
            checkedAt: checkedAt ?? "—",
            total: quantity,
            checked: checked ? quantity : 0
        )
    }
}

struct TimelineDTO: Decodable {
    let id: Int
    let message: String
    let timestamp: String?
    let recordedBy: String

    var model: TimelineEvent {
        TimelineEvent(id: String(id), title: message, description: message, timestamp: timestamp ?? "—", actor: recordedBy)
    }
}

struct ShipmentDTO: Decodable {
    let id: Int
    let name: String
    let status: String
    let mode: String
    let departureDate: String?
    let arrivalDate: String?
    let currentLocation: String
    let clientCargoCount: Int
    let packageCount: Int
    let progress: Double
    let createdAt: String?
    let updates: [ShipmentUpdateDTO]?
    let cargo: [CargoDTO]?

    var model: Shipment {
        Shipment(
            apiID: id,
            id: "SHP-\(id)",
            name: name,
            status: status,
            mode: mode,
            departure: departureDate ?? "—",
            arrival: arrivalDate ?? "—",
            location: currentLocation,
            cargoCount: clientCargoCount,
            packageCount: packageCount,
            progress: progress
        )
    }
}

struct ShipmentUpdateDTO: Decodable {
    let id: Int
    let status: String
    let message: String
    let timestamp: String?
    let recordedBy: String

    func model(shipmentID: String, location: String) -> ShipmentUpdate {
        ShipmentUpdate(id: String(id), shipmentID: shipmentID, location: location, status: status, message: message, timestamp: timestamp ?? "—", actor: recordedBy)
    }
}

struct InvoiceDTO: Decodable {
    let id: Int
    let number: String
    let status: String
    let invoiceDate: String?
    let total: Double
    let balance: Double
    let discount: Double
    let currency: String
    let shipmentId: Int?
    let shipmentName: String
    let cargoId: Int?
    let trackingNumber: String
    let documentUrl: String?
    let items: [InvoiceItemDTO]?
    let payments: [PaymentDTO]?

    var model: Invoice {
        let percentage = total > 0 ? Int((discount / total * 100).rounded()) : 0
        return Invoice(
            apiID: id,
            id: number,
            status: status,
            date: invoiceDate ?? "—",
            total: total,
            balance: balance,
            discount: discount,
            discountPercentage: percentage,
            shipmentID: shipmentName.isEmpty ? shipmentId.map { "SHP-\($0)" } ?? "—" : shipmentName,
            cargoID: trackingNumber.isEmpty ? cargoId.map { "CGO-\($0)" } ?? "—" : trackingNumber,
            currency: currency,
            items: (items ?? []).map(\.model),
            payments: (payments ?? []).map(\.model),
            documentURL: documentUrl.flatMap(URL.init(string:))
        )
    }
}

struct InvoiceItemDTO: Decodable {
    let id: Int
    let label: String
    let quantity: Int
    let unitAmount: Double
    let lineTotal: Double

    var model: InvoiceItem { InvoiceItem(id: String(id), label: label, quantity: quantity, total: lineTotal) }
}

struct PaymentDTO: Decodable {
    let id: Int
    let invoiceId: Int
    let amount: Double
    let currency: String
    let status: String
    let rawStatus: String
    let proofUrl: String?
    let paymentDate: String?
    let reviewedAt: String?
    let transactionId: String
    let notes: String?

    var model: Payment {
        Payment(id: String(id), amount: amount, status: status, date: paymentDate ?? "—", transactionID: transactionId)
    }
}

struct NotificationDTO: Decodable {
    let id: String
    let title: String
    let message: String
    let category: String
    let timestamp: String
    let isRead: Bool
    let destination: String
    let objectType: String
    let objectId: Int?

    var model: AppNotification {
        let tab = AppTab(rawValue: destination.capitalized) ?? (destination == "invoices" ? .invoices : .home)
        return AppNotification(id: id, title: title, message: message, category: category, timestamp: timestamp, isUnread: !isRead, destination: tab, objectID: objectId)
    }
}

struct KYCRecordDTO: Decodable {
    let status: String
    let submittedAt: String?
    let submission: KYCSubmissionDTO?
}

struct CategoryDTO: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
}

struct KYCSubmissionDTO: Codable {
    let id: Int?
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let gender: String
    let clientType: String
    let businessName: String
    let businessCategory: String
    let businessSize: String
    let businessOffering: String
    let tradeIntent: String?
    let goodsCategories: [String]
    let serviceCategories: [String]
    let occupations: [String]
    let interests: [String]
    let location: String
    let dateOfBirth: String?
    let notes: String
    let termsAccepted: Bool
    let updatedAt: String?
}

struct APIEmpty: Decodable {}
struct UpdatedCountDTO: Decodable { let updated: Int }
