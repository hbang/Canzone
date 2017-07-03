import MobileCoreServices
import UIKit

class MediaControlsViewController: UIViewController, MPUNowPlayingDelegate {

	enum InterfaceState: UInt {
		case widgetCollapsed, widgetExpanded
		case notification
	}

	// we need to keep strong references around to these, otherwise they’d be released by ARC and we
	// don’t get to have the goodness they provide
	var nowPlayingController: MPUNowPlayingController!
	var controlsViewController: HaxMediaControlsViewController!

	var artworkView: MPUNowPlayingArtworkView!
	var labelsContainerView: UIView!

	var appNameLabel: UILabel!
	var titleLabel: MPUControlCenterMetadataView!
	var albumLabel: MPUControlCenterMetadataView!
	var artistLabel: MPUControlCenterMetadataView!
	var artistAlbumLabel: MPUControlCenterMetadataView!
	var transportControls: UIView!

	var extrasView: UIView!
	var timeView: UIView!
	var extrasSpacerView: UIView!

	var appNameLabelHeightConstraint: NSLayoutConstraint!
	var titleLabelHeightConstraint: NSLayoutConstraint!
	var albumLabelHeightConstraint: NSLayoutConstraint!
	var artistLabelHeightConstraint: NSLayoutConstraint!
	var artistAlbumLabelHeightConstraint: NSLayoutConstraint!

	var containerHeightConstraint: NSLayoutConstraint!
	//var expandedTopConstraint: NSLayoutConstraint!
	//var collapsedBottomConstraint: NSLayoutConstraint!

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
		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(containerView)

		artworkView = MPUNowPlayingArtworkView()
		artworkView.activated = true
		artworkView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(artworkView)

		labelsContainerView = UIView()
		labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(labelsContainerView)

		// steal the transport controls from MPUControlCenterMediaControlsViewController, which will
		// manage them for us
		transportControls = controlsView.transportControls
		transportControls.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(transportControls)

		appNameLabel = UILabel()
		appNameLabel.translatesAutoresizingMaskIntoConstraints = false
		appNameLabel.font = UIFont.systemFont(ofSize: 15)
		appNameLabel.textColor = UIColor(white: 0.9, alpha: 1)
		labelsContainerView.addSubview(appNameLabel)

		// also steal the labels
		titleLabel = controlsView.value(forKey: "_titleLabel") as! MPUControlCenterMetadataView
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.marqueeEnabled = true
		labelsContainerView.addSubview(titleLabel)

		albumLabel = controlsView.value(forKey: "_albumLabel") as! MPUControlCenterMetadataView
		albumLabel.translatesAutoresizingMaskIntoConstraints = false
		albumLabel.marqueeEnabled = true
		labelsContainerView.addSubview(albumLabel)

		artistLabel = controlsView.value(forKey: "_artistLabel") as! MPUControlCenterMetadataView
		artistLabel.translatesAutoresizingMaskIntoConstraints = false
		artistLabel.marqueeEnabled = true
		labelsContainerView.addSubview(artistLabel)
		
		artistAlbumLabel = controlsView.value(forKey: "_artistAlbumConcatenatedLabel") as! MPUControlCenterMetadataView
		artistAlbumLabel.translatesAutoresizingMaskIntoConstraints = false
		artistAlbumLabel.marqueeEnabled = true
		labelsContainerView.addSubview(artistAlbumLabel)

		appNameLabelHeightConstraint = NSLayoutConstraint(item: appNameLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		titleLabelHeightConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		albumLabelHeightConstraint = NSLayoutConstraint(item: albumLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		artistLabelHeightConstraint = NSLayoutConstraint(item: artistLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		artistAlbumLabelHeightConstraint = NSLayoutConstraint(item: artistAlbumLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		
		labelsContainerView.addConstraints([
			titleLabelHeightConstraint,
			albumLabelHeightConstraint,
			artistLabelHeightConstraint,
			artistAlbumLabelHeightConstraint
		])

		// sean spacer (and our prime minister, mr trumble)
		let spacerView = UIView()
		labelsContainerView.addSubview(spacerView)

		// views within the widget expanded area
		if isWidget {
			containerHeightConstraint = NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
			view.addConstraint(containerHeightConstraint)
		}

		extrasView = UIView()
		extrasView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(extrasView)

		timeView = controlsView.value(forKey: "_timeView") as! UIView
		timeView.translatesAutoresizingMaskIntoConstraints = false
		extrasView.addSubview(timeView)

		extrasSpacerView = UIView()
		extrasSpacerView.translatesAutoresizingMaskIntoConstraints = false
		extrasView.addSubview(extrasSpacerView)

		// do that auto layout stuff
		let margin: CGFloat = isWidget ? 11 : 14

		let metrics: [String: NSNumber] = [
			"heightFactor": 0.4,
			"widgetHeight": 95,

			"margin": margin as NSNumber,
			"doubleMargin": (margin * 2 as CGFloat) as NSNumber, // swift...
			"labelsContainerLeading": isWidget ? (margin - 4) as NSNumber : margin as NSNumber,
			"labelsContainerTrailing": isWidget ? (margin - 6) as NSNumber : margin as NSNumber,
			"labelsContainerTopOutset": isWidget ? -3 : 0,
			"labelsContainerBottomOutset": isWidget ? -6 : 0,

			"labelSpacing": 4,

			"controlsWidth": 160,
			"controlsHeight": isWidget ? 38 : 44
		]

		let views: [String: UIView] = [
			"view": view,
			"containerView": containerView,

			"artworkView": artworkView,
			"labelsContainerView": labelsContainerView,
			"transportControls": transportControls,
			
			"appNameLabel": appNameLabel,
			"titleLabel": titleLabel,
			"albumLabel": albumLabel,
			"artistLabel": artistLabel,
			"artistAlbumLabel": artistAlbumLabel,
			"spacerView": spacerView
		]

		view.hb_addCompactConstraints([
			"containerView.top = self.top + margin",
			"containerView.leading = self.leading + margin",
			"containerView.trailing = self.trailing - margin",
			
			isWidget
				? "containerView.height = widgetHeight - doubleMargin"
				: "containerView.bottom = self.bottom - margin"
		], metrics: metrics, views: views)

		if !isWidget {
			view.hb_addCompactConstraints([
				"self.height = self.width * heightFactor"
			], metrics: metrics, views: views)
		}
		
		containerView.hb_addCompactConstraints([
			"artworkView.top = self.top",
			"artworkView.leading = self.leading",
			"artworkView.bottom = self.bottom",
			"artworkView.width = self.height",

			"labelsContainerView.top = self.top + labelsContainerTopOutset",
			"labelsContainerView.leading = artworkView.trailing + labelsContainerLeading",
			"labelsContainerView.trailing = self.trailing + labelsContainerTrailing",

			"transportControls.top = labelsContainerView.bottom",
			"transportControls.bottom = self.bottom - labelsContainerBottomOutset",
			"transportControls.width = controlsWidth",
			"transportControls.height = controlsHeight",
			"transportControls.centerX = labelsContainerView.centerX"
		], metrics: metrics, views: views)

		// is there not a better, concise way to do this??
		labelsContainerView.hb_addCompactConstraints([
			"appNameLabel.leading = self.leading", "appNameLabel.trailing = self.trailing",
			"titleLabel.leading = self.leading", "titleLabel.trailing = self.trailing",
			"albumLabel.leading = self.leading", "albumLabel.trailing = self.trailing",
			"artistLabel.leading = self.leading", "artistLabel.trailing = self.trailing",
			"artistAlbumLabel.leading = self.leading", "artistAlbumLabel.trailing = self.trailing",
			"spacerView.leading = self.leading", "spacerView.trailing = self.trailing",
		], metrics: metrics, views: views)

		labelsContainerView.hb_addConstraints(withVisualFormat: "V:|[appNameLabel][titleLabel][albumLabel][artistLabel][artistAlbumLabel][spacerView]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)
		
		// set up the now playing controller to send us updates
		nowPlayingController = MPUNowPlayingController()
		nowPlayingController.delegate = self
		nowPlayingController.startUpdating()
	}

	override func viewWillLayoutSubviews() {
		let isSmall = state == .widgetCollapsed

		controlsViewController.controlsHeight = isSmall ? 28 : 32

		super.viewWillLayoutSubviews()

		titleLabel.numberOfLines = isSmall ? 1 : 2
		titleLabel.marqueeEnabled = isSmall

		albumLabel.isHidden = isSmall
		artistLabel.isHidden = isSmall
		artistAlbumLabel.isHidden = !isSmall
		extrasView.isHidden = isSmall

		artistAlbumLabel.marqueeEnabled = true

		switch state {
			case .widgetCollapsed:
				containerHeightConstraint.constant = 95
				break

			case .widgetExpanded:
				containerHeightConstraint.constant = 140
				break

			case .notification:
				break
		}

		let labelExtraMargin: CGFloat = 2

		// the fuck is a greatestFiniteMagnitude? why wasn’t calling it “max”, like, you know, the
		// maximum number possible for the type, good enough?
		let size = CGSize(width: labelsContainerView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
		appNameLabelHeightConstraint.constant = isSmall ? 0 : appNameLabel.sizeThatFits(size).height + labelExtraMargin
		titleLabelHeightConstraint.constant = titleLabel.sizeThatFits(size).height + labelExtraMargin
		albumLabelHeightConstraint.constant = isSmall ? 0 : albumLabel.sizeThatFits(size).height + labelExtraMargin
		artistLabelHeightConstraint.constant = isSmall ? 0 : artistLabel.sizeThatFits(size).height + labelExtraMargin
		artistAlbumLabelHeightConstraint.constant = isSmall ? artistAlbumLabel.sizeThatFits(size).height + labelExtraMargin : 0
	}

	// MARK: - Now playing

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, nowPlayingInfoDidChange info: [AnyHashable: Any]!) {
		artworkView.artworkImage = nowPlayingController.currentNowPlayingArtwork

		if appNameLabel != nil {
			if nowPlayingController.nowPlayingAppDisplayID == nil {
				appNameLabel.text = ""
			} else {
				if let app = LSApplicationProxy(forIdentifier: nowPlayingController.nowPlayingAppDisplayID) {
					appNameLabel.text = app.localizedName.localizedUppercase
				}
			}
		}

		view.setNeedsLayout()
	}

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, playbackStateDidChange state: Bool) {
		artworkView.setActivated(state, animated: true)
	}
	
}
