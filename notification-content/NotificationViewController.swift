import UIKit
import UserNotifications
import UserNotificationsUI

@objc(NotificationViewController)
class NotificationViewController: MediaControlsViewController, UNNotificationContentExtension {

	// MARK: - Notification content
	
	func didReceive(_ notification: UNNotification) {
		// do nothing, just have to implement this to make the protocol happy
	}
	
}
