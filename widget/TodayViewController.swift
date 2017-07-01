import UIKit
import NotificationCenter

@objc(TodayViewController)
class TodayViewController: MediaControlsViewController, NCWidgetProviding {
	
	// MARK: - Init

	init(nibName: String?, bundle: Bundle?) {
		super.init(state: .widgetCollapsed)
	}

	required init(coder: NSCoder) {
		// shut up
		fatalError("")
	}

	// MARK: - View controller

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// indicate that we support an expanded style
		extensionContext!.widgetLargestAvailableDisplayMode = .expanded
	}

	// MARK: - Widget

	var controlsState: MediaControlsViewController.InterfaceState {
		// map the widget display mode to the matching InterfaceState
		switch extensionContext!.widgetActiveDisplayMode {
			case .compact:
				return .widgetCollapsed
			
			case .expanded:
				return .widgetExpanded
		}
	}
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		// set the content size. if our preferred height is larger than the maximum we’re currently
		// allowed, then we need to just go with the max. this also makes it use ios’s default compact
		// height when in compact mode (currently, 95pt)
		preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, 380))

		// set the expanded mode on the controls
		setState(controlsState, animated: true)
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		// make the protocol happy by saying we have new data
		completionHandler(.newData)
	}
	
}
