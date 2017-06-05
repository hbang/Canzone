import UIKit
import NotificationCenter

@objc(TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

	var controlsViewController: MediaControlsViewController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// indicate that we support an expanded style
		extensionContext!.widgetLargestAvailableDisplayMode = .expanded
		
		// instantiate the view controller
		controlsViewController = MediaControlsViewController(state: controlsState)
		
		// make it fill the entire space
		controlsViewController.view.frame = view.bounds
		controlsViewController.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		
		// add it as a child view controller
		addChildViewController(controlsViewController)
		view.addSubview(controlsViewController.view)
	}
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		// set the content size. if our preferred height is larger than the maximum we’re currently
		// allowed, then we need to just go with the max. this also makes it use ios’s default compact
		// height when in compact mode (currently, 95pt)
		preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, 380))

		// set the expanded mode on the controls
		controlsViewController.setState(controlsState, animated: true)
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		completionHandler(.newData)
	}

	var controlsState: MediaControlsViewController.InterfaceState {
		switch extensionContext!.widgetActiveDisplayMode {
			case .compact:
				return .widgetCollapsed
			
			case .expanded:
				return .widgetExpanded
		}
	}
	
}
