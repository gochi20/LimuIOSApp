import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NotificationCenter.default.post(
            name: .limuDidRegisterForRemoteNotifications,
            object: nil,
            userInfo: ["token": token]
        )
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(
            name: .limuDidFailToRegisterForRemoteNotifications,
            object: nil,
            userInfo: ["error": error.localizedDescription]
        )
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationCenter.default.post(name: .limuRemoteNotificationReceived, object: nil, userInfo: userInfo)
        completionHandler(.newData)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        NotificationCenter.default.post(
            name: .limuRemoteNotificationReceived,
            object: nil,
            userInfo: notification.request.content.userInfo
        )
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationCenter.default.post(
            name: .limuRemoteNotificationTapped,
            object: nil,
            userInfo: response.notification.request.content.userInfo
        )
        completionHandler()
    }
}

extension Notification.Name {
    static let limuDidRegisterForRemoteNotifications = Notification.Name("limuDidRegisterForRemoteNotifications")
    static let limuDidFailToRegisterForRemoteNotifications = Notification.Name("limuDidFailToRegisterForRemoteNotifications")
    static let limuRemoteNotificationReceived = Notification.Name("limuRemoteNotificationReceived")
    static let limuRemoteNotificationTapped = Notification.Name("limuRemoteNotificationTapped")
}
