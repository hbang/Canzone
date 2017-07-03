import UIKit
import UserNotifications
import UserNotificationsUI

@objc(NotificationViewController)
class NotificationViewController: MediaControlsViewController, UNNotificationContentExtension {
	
	// MARK: - Init

	init(nibName: String?, bundle: Bundle?) {
		super.init(state: .notification)
	}

	required init(coder: NSCoder) {
		// shut up
		fatalError("")
	}

	// MARK: - Notification content
	
	func didReceive(_ notification: UNNotification) {
		// do nothing, just have to implement this to make the protocol happy
	}
	
}
