import Foundation
import UserNotifications
import UIKit

struct BadgeManager {
    static func setBadgeCount(_ count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error = error {
                    print("Badge count error: \(error)")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
    
    static func clearBadge() {
        setBadgeCount(0)
    }
}