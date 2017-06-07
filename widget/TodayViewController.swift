import UIKit
import NotificationCenter

@objc(TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

	var viewController: MPUControlCenterMediaControlsViewController!
	var sorryLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// indicate that we support an expanded style
		extensionContext!.widgetLargestAvailableDisplayMode = .expanded
		
		// instantiate the view controller
		viewController = MPUControlCenterMediaControlsViewController()
		
		// make it fill the entire space
		viewController.view.frame = CGRect(x: 0, y: 24, width: view.frame.size.width, height: view.frame.size.height - 24)
		viewController.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		
		// add it as a child view controller
		addChildViewController(viewController)
		view.addSubview(viewController.view)

		sorryLabel = UILabel(frame: CGRect(x: 20, y: 20, width: view.frame.size.width - 40, height: view.frame.size.height - 40))
		sorryLabel.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		sorryLabel.textColor = UIColor(white: 0, alpha: 0.7)
		sorryLabel.textAlignment = .center
		sorryLabel.numberOfLines = 0
		sorryLabel.font = UIFont.systemFont(ofSize: 15)
		sorryLabel.text = "Please tap “Show More” above\n(Collapsed mode coming soon!)"
		view.addSubview(sorryLabel)

		update(displayMode: extensionContext!.widgetActiveDisplayMode)
	}
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		// set the content size. if our preferred height is larger than the maximum we’re currently
		// allowed, then we need to just go with the max. this also makes it use ios’s default compact
		// height when in compact mode (currently, 95pt)
		preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, 380))

		update(displayMode: activeDisplayMode)
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		completionHandler(NCUpdateResult.newData)
	}

	func update(displayMode: NCWidgetDisplayMode) {
		let isExpanded = displayMode == .expanded
		sorryLabel.isHidden = isExpanded
		viewController.view.isHidden = !isExpanded
	}
	
}
