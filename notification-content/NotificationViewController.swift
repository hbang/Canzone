import UIKit
import UserNotifications
import UserNotificationsUI

@objc(NotificationViewController)
class NotificationViewController: UIViewController, UNNotificationContentExtension {
	
	// MARK: - View controller

	override func loadView() {
		super.loadView()
		
		// instantiate the view controller
		let viewController = MediaControlsViewController()
		
		// make it fill the entire space
		viewController.view.frame = view.bounds
		viewController.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		
		// add it as a child view controller
		addChildViewController(viewController)
		view.addSubview(viewController.view)
	}

	// MARK: - Notification content
	
	func didReceive(_ notification: UNNotification) {
		// do nothing, just have to implement this to make the protocol happy
	}
	
}
