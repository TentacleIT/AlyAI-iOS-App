import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Detect user's current location for personalization
        Task { @MainActor in
            LocationService.shared.detectCurrentLocation()
        }
        
        // Configure App Check
        #if DEBUG
        // Use debug provider for development/simulator
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        // Use DeviceCheck provider for production
        let providerFactory = DeviceCheckProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        // Set Messaging delegate
        Messaging.messaging().delegate = self
        
        // Initial update of quick actions
        QuickActionService.shared.updateQuickActions()
        
        // Handle launch from a shortcut item
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            _ = QuickActionService.shared.handleShortcutItem(shortcutItem)
        }

        return true
    }

    // This is called when the app is already running and a shortcut is used.
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handled = QuickActionService.shared.handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }
    
    // MARK: - Messaging Delegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        guard let token = fcmToken else { return }
        
        // Save token to Firestore
        FirestoreManager.shared.updateDeviceToken(token)
    }
    
    // MARK: - UNUserNotificationCenter Delegate
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print(userInfo)
        
        completionHandler([[.banner, .badge, .sound]])
    }
    
    // Handle background notification clicks
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
        
        completionHandler()
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
