import UIKit
import NotificationCenter

@objc(TodayViewController)
class TodayViewController: MediaControlsViewController, NCWidgetProviding {

	var extrasView = UIView()

	var timeView: UIView {
		return controlsViewController.view!.value(forKey: "_timeView") as! UIView
	}

	var widgetMaximumSize = CGSize.zero
	var labelsContainerViewHeightConstraint: NSLayoutConstraint!
	
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

		controlsViewController.viewWillAppear(true)

		extrasView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(extrasView)

		timeView.translatesAutoresizingMaskIntoConstraints = false
		extrasView.addSubview(timeView)

		let metrics: [String: NSNumber] = [
			"margin": 6,
			"timeTop": 16,
			"timeInset": 3,
			"timeHeight": 28
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
		extrasView.hb_addConstraints(withVisualFormat: "V:|-timeTop-[timeView(timeHeight)]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)

		containerView.hb_addConstraints(withVisualFormat: "V:|[labelsContainerView]-margin-[extrasView]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)

		labelsContainerViewHeightConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		labelsContainerView.addConstraint(labelsContainerViewHeightConstraint)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// indicate that we support an expanded style
		extensionContext!.widgetLargestAvailableDisplayMode = .expanded
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let isSmall = state == .widgetCollapsed
		
		extrasView.alpha = isSmall ? 0 : 1

		labelsContainerViewHeightConstraint.isActive = isSmall

		if isSmall {
			labelsContainerViewHeightConstraint.constant = widgetMaximumSize.height - (6 * 2)
		}

		// determine our height. i hardcoded the margin from the superclass, sorry
		let maxSize = CGSize(width: widgetMaximumSize.width - (6 * 2), height: widgetMaximumSize.height)
		var actualHeight = containerView.sizeThatFits(maxSize).height + (6 * 2)

		if !isSmall {
			actualHeight += extrasView.sizeThatFits(maxSize).height
		}

		// set the content size. if our preferred height is larger than the maximum we’re currently
		// allowed, then we need to just go with the max. this also makes it use ios’s default compact
		// height when in compact mode (currently, ~95pt)
		preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, actualHeight))
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
		// set the expanded mode on the controls (which will also call setNeedsLayout())
		widgetMaximumSize = maxSize
		state = controlsState

		// update the content and size
		updateMetadata()
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		// make the protocol happy by saying we have new data
		completionHandler(.newData)
	}
	
}
