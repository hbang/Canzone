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

	// MARK: - View controller

	override func loadView() {
		super.loadView()

		// ensure the view is the same height as we defined in the Info.plist, so we don't get ugly
		// window resizing between when the window opens and when the content is fully loaded
		view.hb_addCompactConstraint("self.height = self.width * heightFactor", metrics: [ "heightFactor": 0.4 ], views: nil)
	}

	// MARK: - Notification content
	
	func didReceive(_ notification: UNNotification) {
		// do nothing, just have to implement this to make the protocol happy
	}
	
}
