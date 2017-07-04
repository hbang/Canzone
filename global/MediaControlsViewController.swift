import MobileCoreServices
import UIKit

class MediaControlsViewController: UIViewController, MPUNowPlayingDelegate {

	enum InterfaceState: UInt {
		case widgetCollapsed, widgetExpanded
		case notification
	}

	// we need to keep strong references to these around, otherwise they’d be released by ARC and we
	// don’t get to have the goodness they provide
	var nowPlayingController: MPUNowPlayingController!
	var controlsViewController: HaxMediaControlsViewController!

	var containerView: UIView!
	var artworkView: MPUNowPlayingArtworkView!
	var labelsContainerView: UIView!

	var titleLabel: MPUControlCenterMetadataView!
	var artistAlbumLabel: MPUControlCenterMetadataView!
	var transportControls: UIView!

	var titleLabelHeightConstraint: NSLayoutConstraint!
	var artistAlbumLabelHeightConstraint: NSLayoutConstraint!

	var state = InterfaceState.notification {
		didSet {
			view.setNeedsLayout()
		}
	}

	// MARK: - Init

	init(state: InterfaceState) {
		super.init(nibName: nil, bundle: nil)

		self.state = state
	}

	required init(coder: NSCoder) {
		// shut up
		fatalError("")
	}
	
	// MARK: - View controller
	
	override func loadView() {
		super.loadView()

		let isWidget = state != .notification

		view.autoresizingMask = [ .flexibleWidth ]

		controlsViewController = HaxMediaControlsViewController()
		let controlsView = controlsViewController.view!
		
		// construct the views
		containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(containerView)

		artworkView = MPUNowPlayingArtworkView()
		artworkView.translatesAutoresizingMaskIntoConstraints = false
		artworkView.activated = true
		containerView.addSubview(artworkView)

		labelsContainerView = UIView()
		labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(labelsContainerView)

		// also steal the labels
		titleLabel = controlsView.value(forKey: "_titleLabel") as! MPUControlCenterMetadataView
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.numberOfLines = 1
		titleLabel.marqueeEnabled = true
		titleLabel.isUserInteractionEnabled = false
		labelsContainerView.addSubview(titleLabel)
		
		artistAlbumLabel = controlsView.value(forKey: "_artistAlbumConcatenatedLabel") as! MPUControlCenterMetadataView
		artistAlbumLabel.translatesAutoresizingMaskIntoConstraints = false
		artistAlbumLabel.numberOfLines = 1
		artistAlbumLabel.marqueeEnabled = true
		artistAlbumLabel.isUserInteractionEnabled = false
		labelsContainerView.addSubview(artistAlbumLabel)

		// steal the transport controls from MPUControlCenterMediaControlsViewController, which will
		// manage them for us
		transportControls = controlsView.transportControls
		transportControls.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(transportControls)

		// sean spacer (and our prime minister, mr trumble)
		let spacerView = UIView()
		spacerView.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(spacerView)

		// do that auto layout stuff
		let widgetHeight: CGFloat = 95
		let margin: CGFloat = isWidget ? 6 : 12
		let artworkInset: CGFloat = isWidget ? 4 : 2

		let metrics: [String: NSNumber] = [
			"widgetHeight": widgetHeight as NSNumber,
			"widgetArtworkSize": (widgetHeight - (margin + artworkInset) * 2) as NSNumber,

			"margin": margin as NSNumber,
			"artworkInset": artworkInset as NSNumber,
			"innerMargin": isWidget ? 6 : 8,

			"controlsWidth": 160,
			"controlsHeight": isWidget ? 38 : 44
		]

		let views: [String: UIView] = [
			"view": view,
			"containerView": containerView,

			"artworkView": artworkView,
			"labelsContainerView": labelsContainerView,

			"titleLabel": titleLabel,
			"artistAlbumLabel": artistAlbumLabel,
			"spacerView": spacerView,
			"transportControls": transportControls
		]

		view.hb_addCompactConstraints([
			"containerView.top = self.top + margin",
			"containerView.leading = self.leading + margin",
			"containerView.trailing = self.trailing - margin"
		], metrics: metrics, views: views)

		containerView.hb_addCompactConstraints([
			"artworkView.top = containerView.top + artworkInset",
			"artworkView.width = artworkView.height"
		], metrics: metrics, views: views)

		if !isWidget {
			view.hb_addCompactConstraint("containerView.bottom = self.bottom - margin", metrics: metrics, views: views)
			
			containerView.hb_addCompactConstraints([
				"artworkView.bottom = containerView.bottom - artworkInset"
				"labelsContainerView.top = containerView.top",
				"labelsContainerView.bottom = containerView.bottom"
			], metrics: metrics, views: views)
		}

		containerView.hb_addConstraints(withVisualFormat: "H:|-artworkInset-[artworkView\(isWidget ? "(==widgetArtworkSize)" : "")]-innerMargin-[labelsContainerView]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)

		// is there not a better, concise way to do this??
		labelsContainerView.hb_addCompactConstraints([
			"titleLabel.leading = self.leading", "titleLabel.trailing = self.trailing",
			"artistAlbumLabel.leading = self.leading", "artistAlbumLabel.trailing = self.trailing",
			"spacerView.leading = self.leading", "spacerView.trailing = self.trailing",

			"transportControls.width = controlsWidth",
			"transportControls.centerX = labelsContainerView.centerX"
		], metrics: metrics, views: views)

		labelsContainerView.hb_addConstraints(withVisualFormat: "V:|[titleLabel][artistAlbumLabel][spacerView][transportControls(controlsHeight)]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)

		// manually make some constraints for the label heights
		titleLabelHeightConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		artistAlbumLabelHeightConstraint = NSLayoutConstraint(item: artistAlbumLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		
		labelsContainerView.addConstraints([
			titleLabelHeightConstraint,
			artistAlbumLabelHeightConstraint
		])
		
		// set up the now playing controller to send us updates
		nowPlayingController = MPUNowPlayingController()
		nowPlayingController.delegate = self
		nowPlayingController.startUpdating()
	}

	override func viewWillLayoutSubviews() {
		let isSmall = state == .widgetCollapsed

		controlsViewController.controlsHeight = isSmall ? 28 : 32

		super.viewWillLayoutSubviews()

		// numberOfLines and marqueeEnabled can be changed behind our backs (i should really just
		// construct these labels myself... not enough time now) so set them again here
		titleLabel.numberOfLines = isSmall ? 1 : 2
		artistAlbumLabel.numberOfLines = isSmall ? 1 : 2

		// if titleLabel isn't 1 line, this won't do anything but will still align it with the others
		titleLabel.marqueeEnabled = isSmall
		artistAlbumLabel.marqueeEnabled = isSmall
		
		artistAlbumLabel.isHidden = false

		let labelExtraMargin: CGFloat = 2

		// the fuck is a greatestFiniteMagnitude? why wasn’t calling it “max”, like, you know, the
		// maximum number possible for the type, good enough?
		let size = CGSize(width: labelsContainerView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
		titleLabelHeightConstraint.constant = titleLabel.sizeThatFits(size).height + labelExtraMargin
		artistAlbumLabelHeightConstraint.constant = artistAlbumLabel.sizeThatFits(size).height + labelExtraMargin
	}

	// MARK: - Now playing

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, nowPlayingInfoDidChange info: [AnyHashable: Any]!) {
		artworkView.artworkImage = nowPlayingController.currentNowPlayingArtwork
		view.setNeedsLayout()
	}

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, playbackStateDidChange state: Bool) {
		artworkView.setActivated(state, animated: true)
	}
	
}
