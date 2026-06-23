import Foundation

struct Cargo: Identifiable, Hashable {
    let apiID: Int
    let id: String
    let status: String
    let summary: String
    let packages: Int
    let weight: Double
    let volume: Double
    let location: String
    let financeStatus: String
    let shipmentName: String
    let createdAt: String
    let readyForCollection: Bool
    let collectionLocation: String?
    let notes: String?
    let checkedPackages: Int
    let invoiceAPIID: Int?

    init(
        apiID: Int = 0,
        id: String,
        status: String,
        summary: String,
        packages: Int,
        weight: Double,
        volume: Double,
        location: String,
        financeStatus: String,
        shipmentName: String,
        createdAt: String,
        readyForCollection: Bool,
        collectionLocation: String?,
        notes: String?,
        checkedPackages: Int = 0,
        invoiceAPIID: Int? = nil
    ) {
        self.apiID = apiID
        self.id = id
        self.status = status
        self.summary = summary
        self.packages = packages
        self.weight = weight
        self.volume = volume
        self.location = location
        self.financeStatus = financeStatus
        self.shipmentName = shipmentName
        self.createdAt = createdAt
        self.readyForCollection = readyForCollection
        self.collectionLocation = collectionLocation
        self.notes = notes
        self.checkedPackages = checkedPackages
        self.invoiceAPIID = invoiceAPIID
    }
}

struct CargoPackage: Identifiable, Hashable {
    let id: String
    let content: String
    let quantity: Int
    let type: String
    let code: String
    let courierTracking: String
    let checkedAt: String
    let total: Int
    let checked: Int
}

struct TimelineEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let timestamp: String
    let actor: String
}

struct Shipment: Identifiable, Hashable {
    let apiID: Int
    let id: String
    let name: String
    let status: String
    let mode: String
    let departure: String
    let arrival: String
    let location: String
    let cargoCount: Int
    let packageCount: Int
    let progress: Double

    init(
        apiID: Int = 0,
        id: String,
        name: String,
        status: String,
        mode: String,
        departure: String,
        arrival: String,
        location: String,
        cargoCount: Int,
        packageCount: Int,
        progress: Double = 0
    ) {
        self.apiID = apiID
        self.id = id
        self.name = name
        self.status = status
        self.mode = mode
        self.departure = departure
        self.arrival = arrival
        self.location = location
        self.cargoCount = cargoCount
        self.packageCount = packageCount
        self.progress = progress
    }
}

struct ShipmentUpdate: Identifiable, Hashable {
    let id: String
    let shipmentID: String
    let location: String
    let status: String
    let message: String
    let timestamp: String
    let actor: String
}

struct InvoiceItem: Identifiable, Hashable {
    let id: String
    let label: String
    let quantity: Int
    let total: Double
}

struct Payment: Identifiable, Hashable {
    let id: String
    let amount: Double
    let status: String
    let date: String
    let transactionID: String
}

struct Invoice: Identifiable, Hashable {
    let apiID: Int
    let id: String
    let status: String
    let date: String
    let total: Double
    let balance: Double
    let discount: Double
    let discountPercentage: Int
    let shipmentID: String
    let cargoID: String
    let currency: String
    let items: [InvoiceItem]
    let payments: [Payment]
    let documentURL: URL?

    init(
        apiID: Int = 0,
        id: String,
        status: String,
        date: String,
        total: Double,
        balance: Double,
        discount: Double,
        discountPercentage: Int,
        shipmentID: String,
        cargoID: String,
        currency: String,
        items: [InvoiceItem],
        payments: [Payment],
        documentURL: URL? = nil
    ) {
        self.apiID = apiID
        self.id = id
        self.status = status
        self.date = date
        self.total = total
        self.balance = balance
        self.discount = discount
        self.discountPercentage = discountPercentage
        self.shipmentID = shipmentID
        self.cargoID = cargoID
        self.currency = currency
        self.items = items
        self.payments = payments
        self.documentURL = documentURL
    }
}

struct AppNotification: Identifiable, Hashable {
    let id: String
    let title: String
    let message: String
    let category: String
    let timestamp: String
    var isUnread: Bool
    let destination: AppTab
    let objectID: Int?

    init(id: String, title: String, message: String, category: String, timestamp: String, isUnread: Bool, destination: AppTab, objectID: Int? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.category = category
        self.timestamp = timestamp
        self.isUnread = isUnread
        self.destination = destination
        self.objectID = objectID
    }
}

enum MockData {
    static let cargo: [Cargo] = [
        Cargo(id: "LMU-CGO-0041", status: "In Warehouse", summary: "Electronics & Accessories", packages: 8, weight: 142.5, volume: 0.92, location: "Limu Warehouse, Guangzhou", financeStatus: "Payment Pending", shipmentName: "SEA-GZ-ACC-JUN25", createdAt: "2025-06-02", readyForCollection: false, collectionLocation: nil, notes: "Awaiting payment confirmation before loading."),
        Cargo(id: "LMU-CGO-0038", status: "Ready for Collection", summary: "Clothing & Footwear", packages: 14, weight: 98, volume: 1.24, location: "Limu Warehouse, Accra", financeStatus: "Approved", shipmentName: "SEA-GZ-ACC-MAY25", createdAt: "2025-04-18", readyForCollection: true, collectionLocation: "Limu Accra Depot, Tema Road", notes: nil),
        Cargo(id: "LMU-CGO-0035", status: "In Transit", summary: "Kitchen Appliances", packages: 5, weight: 210, volume: 2.1, location: "At Sea – Atlantic Ocean", financeStatus: "Paid", shipmentName: "SEA-GZ-ACC-MAY25", createdAt: "2025-03-30", readyForCollection: false, collectionLocation: nil, notes: nil),
        Cargo(id: "LMU-CGO-0029", status: "Collected", summary: "Hardware & Tools", packages: 3, weight: 56, volume: 0.38, location: "Collected", financeStatus: "Paid", shipmentName: "SEA-GZ-ACC-MAR25", createdAt: "2025-02-10", readyForCollection: false, collectionLocation: "Limu Accra Depot, Tema Road", notes: nil)
    ]

    static let packages: [CargoPackage] = [
        CargoPackage(id: "PKG-0041-01", content: "Bluetooth Speakers (x6)", quantity: 6, type: "Carton", code: "C-001", courierTracking: "YT2204891023GH", checkedAt: "2025-06-03 11:30", total: 6, checked: 6),
        CargoPackage(id: "PKG-0041-02", content: "Phone Accessories", quantity: 24, type: "Carton", code: "C-002", courierTracking: "YT2204891024GH", checkedAt: "2025-06-03 11:35", total: 24, checked: 24),
        CargoPackage(id: "PKG-0041-03", content: "USB Hubs & Cables", quantity: 50, type: "Bag", code: "B-001", courierTracking: "YT2204891025GH", checkedAt: "2025-06-03 11:42", total: 50, checked: 50)
    ]

    static let cargoTimeline: [TimelineEvent] = [
        TimelineEvent(id: "EV-001", title: "Cargo Created", description: "Cargo registered in system", timestamp: "2025-06-02 09:14", actor: "System"),
        TimelineEvent(id: "EV-002", title: "Packages Verified", description: "All 8 packages counted and confirmed", timestamp: "2025-06-03 11:30", actor: "David K."),
        TimelineEvent(id: "EV-003", title: "Warehouse Check Passed", description: "Cargo passed warehouse inspection", timestamp: "2025-06-04 14:00", actor: "Mary O."),
        TimelineEvent(id: "EV-004", title: "Invoice Generated", description: "Invoice INV-2025-0156 issued", timestamp: "2025-06-04 16:45", actor: "Finance"),
        TimelineEvent(id: "EV-005", title: "Awaiting Payment", description: "Cargo on hold pending payment confirmation", timestamp: "2025-06-05 08:00", actor: "System")
    ]

    static let shipments: [Shipment] = [
        Shipment(id: "SHP-0018", name: "SEA-GZ-ACC-JUN25", status: "Loading", mode: "Sea Freight", departure: "2025-06-20", arrival: "2025-08-05", location: "Guangzhou Port, China", cargoCount: 1, packageCount: 8),
        Shipment(id: "SHP-0015", name: "SEA-GZ-ACC-MAY25", status: "In Transit", mode: "Sea Freight", departure: "2025-05-10", arrival: "2025-06-28", location: "Atlantic Ocean – ETA 18 days", cargoCount: 2, packageCount: 19),
        Shipment(id: "SHP-0012", name: "SEA-GZ-ACC-MAR25", status: "Completed", mode: "Sea Freight", departure: "2025-03-05", arrival: "2025-04-22", location: "Delivered", cargoCount: 1, packageCount: 3)
    ]

    static let shipmentUpdates: [ShipmentUpdate] = [
        ShipmentUpdate(id: "UPD-018-001", shipmentID: "SHP-0018", location: "Guangzhou Port, China", status: "Loading", message: "Container TCKU8821034 assigned and loading has commenced at Guangzhou Port.", timestamp: "2025-06-08 10:00", actor: "Operations"),
        ShipmentUpdate(id: "UPD-018-002", shipmentID: "SHP-0018", location: "Limu Warehouse, Guangzhou", status: "Loading", message: "Cargo consolidation complete. All client cargo packed and sealed.", timestamp: "2025-06-05 15:30", actor: "Warehouse"),
        ShipmentUpdate(id: "UPD-015-001", shipmentID: "SHP-0015", location: "Atlantic Ocean", status: "In Transit", message: "Vessel MV Atlantic Horizon on schedule. No disruptions reported. ETA remains 28 June.", timestamp: "2025-06-09 06:00", actor: "Operations"),
        ShipmentUpdate(id: "UPD-015-002", shipmentID: "SHP-0015", location: "Suez Canal", status: "In Transit", message: "Vessel cleared Suez Canal transit successfully. No delays.", timestamp: "2025-05-28 14:30", actor: "Operations"),
        ShipmentUpdate(id: "UPD-015-003", shipmentID: "SHP-0015", location: "Port Said, Egypt", status: "In Transit", message: "Vessel departed Port Said anchorage. Heading south through Red Sea.", timestamp: "2025-05-27 09:00", actor: "Operations"),
        ShipmentUpdate(id: "UPD-012-001", shipmentID: "SHP-0012", location: "Tema Port, Ghana", status: "Completed", message: "All cargo cleared and available for client collection at Limu Accra Depot.", timestamp: "2025-04-25 09:00", actor: "Operations")
    ]

    static let invoices: [Invoice] = [
        Invoice(id: "INV-2025-0156", status: "Not Paid", date: "2025-06-04", total: 2450, balance: 2450, discount: 0, discountPercentage: 0, shipmentID: "SHP-0018", cargoID: "LMU-CGO-0041", currency: "USD", items: [
            InvoiceItem(id: "ITM-001", label: "Handling Fee", quantity: 1, total: 80),
            InvoiceItem(id: "ITM-002", label: "Storage – 3 days", quantity: 3, total: 45),
            InvoiceItem(id: "ITM-003", label: "Customs Documentation", quantity: 1, total: 120),
            InvoiceItem(id: "ITM-004", label: "Sea Freight (0.92 CBM)", quantity: 1, total: 1885),
            InvoiceItem(id: "ITM-005", label: "Destination Charges", quantity: 1, total: 320)
        ], payments: []),
        Invoice(id: "INV-2025-0144", status: "Partially Paid", date: "2025-05-02", total: 1890, balance: 890, discount: 0, discountPercentage: 0, shipmentID: "SHP-0015", cargoID: "LMU-CGO-0038", currency: "USD", items: [
            InvoiceItem(id: "ITM-006", label: "Handling Fee", quantity: 1, total: 60),
            InvoiceItem(id: "ITM-007", label: "Sea Freight (1.24 CBM)", quantity: 1, total: 1550),
            InvoiceItem(id: "ITM-008", label: "Destination Charges", quantity: 1, total: 280)
        ], payments: [Payment(id: "PAY-001", amount: 1000, status: "Approved", date: "2025-05-14", transactionID: "TXN-GH-88420")]),
        Invoice(id: "INV-2025-0128", status: "Paid", date: "2025-03-12", total: 980, balance: 0, discount: 50, discountPercentage: 5, shipmentID: "SHP-0012", cargoID: "LMU-CGO-0029", currency: "USD", items: [
            InvoiceItem(id: "ITM-009", label: "Sea Freight (0.38 CBM)", quantity: 1, total: 750),
            InvoiceItem(id: "ITM-010", label: "Destination Charges", quantity: 1, total: 180),
            InvoiceItem(id: "ITM-011", label: "Loyalty Discount", quantity: 1, total: -50)
        ], payments: [Payment(id: "PAY-002", amount: 980, status: "Approved", date: "2025-03-20", transactionID: "TXN-GH-71203")])
    ]

    static let notifications: [AppNotification] = [
        AppNotification(id: "NOT-001", title: "Cargo Ready for Collection", message: "LMU-CGO-0038 (Clothing & Footwear) is ready for pickup at Limu Accra Depot, Tema Road.", category: "Cargo", timestamp: "2025-06-09 08:30", isUnread: true, destination: .cargo),
        AppNotification(id: "NOT-002", title: "Invoice INV-2025-0156 Issued", message: "A new invoice of $2,450.00 has been raised for cargo LMU-CGO-0041. Please arrange payment.", category: "Invoice", timestamp: "2025-06-04 16:45", isUnread: true, destination: .invoices),
        AppNotification(id: "NOT-003", title: "Shipment Update – SEA-GZ-ACC-MAY25", message: "Your shipment has cleared Suez Canal and is on schedule for arrival on 28 June 2025.", category: "Shipment", timestamp: "2025-05-28 14:30", isUnread: false, destination: .shipments),
        AppNotification(id: "NOT-004", title: "Payment Received – INV-2025-0144", message: "Your payment of $1,000.00 has been approved. Remaining balance: $890.00.", category: "Payment", timestamp: "2025-05-15 10:00", isUnread: false, destination: .invoices)
    ]

    static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(value.rounded() == value ? 0 : 2)))
            .replacingOccurrences(of: "US", with: "")
    }
}
