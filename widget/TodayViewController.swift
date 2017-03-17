import UIKit
import NotificationCenter

@objc(TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// indicate that we support an expanded style
		extensionContext!.widgetLargestAvailableDisplayMode = .expanded
		
		// instantiate the view controller
		let viewController = MPUControlCenterMediaControlsViewController()
		
		// make it fill the entire space
		viewController.view.frame = CGRect(x: 0, y: 20, width: view.frame.size.width, height: view.frame.size.height - 20)
		viewController.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		
		// add it as a child view controller
		addChildViewController(viewController)
		view.addSubview(viewController.view)
	}
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		// set the content size. if our preferred height is larger than the maximum we’re currently
		// allowed, then we need to just go with the max. this also makes it use ios’s default compact
		// height when in compact mode (currently, 95pt)
		preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, 370))
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		completionHandler(NCUpdateResult.newData)
	}
	
}
