import UIKit
import NotificationCenter

@objc(TodayViewController)
class TodayViewController: MediaControlsViewController, NCWidgetProviding {

	var extrasView: UIView!
	var timeView: UIView!
	var extrasSpacerView: UIView!
	
	// MARK: - Init

	init(nibName: String?, bundle: Bundle?) {
		super.init(state: .widgetCollapsed)
	}

	required init(coder: NSCoder) {
		// shut up
		fatalError("")
	}

	// MARK: - View controller

	override func loadView() {
		super.loadView()

		let controlsView = controlsViewController.view!

		extrasView = UIView()
		extrasView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(extrasView)

		timeView = controlsView.value(forKey: "_timeView") as! UIView
		timeView.translatesAutoresizingMaskIntoConstraints = false
		extrasView.addSubview(timeView)

		let metrics: [String: NSNumber] = [
			"margin": 6,
			"timeInset": 6,
			"timeHeight": 60,
		]

		let views: [String: UIView] = [
			"containerView": containerView,
			"labelsContainerView": labelsContainerView,
			"extrasView": extrasView,

			"timeView": timeView
		]

		containerView.hb_addCompactConstraints([
			"extrasView.top = labelsContainerView.bottom",
			"extrasView.bottom = containerView.bottom",
			"extrasView.left = containerView.left",
			"extrasView.right = containerView.right"
		], metrics: metrics, views: views)

		extrasView.hb_addConstraints(withVisualFormat: "H:|-timeInset-[timeView]-timeInset-|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)
		extrasView.hb_addConstraints(withVisualFormat: "V:|[timeView(timeHeight)]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)

		containerView.hb_addConstraints(withVisualFormat: "V:|[labelsContainerView][extrasView]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// indicate that we support an expanded style
		extensionContext!.widgetLargestAvailableDisplayMode = .expanded
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let isSmall = self.state == .widgetCollapsed
		
		extrasView.alpha = isSmall ? 0 : 1
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
		preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, 186))

		// set the expanded mode on the controls (which will also call setNeedsLayout())
		state = controlsState
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		// make the protocol happy by saying we have new data
		completionHandler(.newData)
	}
	
}
