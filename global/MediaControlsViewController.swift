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

	var titleLabel: MPUControlCenterMetadataView!
	var albumLabel: MPUControlCenterMetadataView!
	var artistLabel: MPUControlCenterMetadataView!
	var artistAlbumLabel: MPUControlCenterMetadataView!
	var transportControls: UIView!

	var titleLabelHeightConstraint: NSLayoutConstraint!
	var albumLabelHeightConstraint: NSLayoutConstraint!
	var artistLabelHeightConstraint: NSLayoutConstraint!
	var artistAlbumLabelHeightConstraint: NSLayoutConstraint!

	var state = InterfaceState.notification

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

		view.autoresizingMask = [ .flexibleWidth ]

		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(containerView)
		
		// construct the views
		// we disable user interaction on the artworkView as this allows touches to fall through to the
		// tap gesture recognizer in springboard, which will open the app
		artworkView = MPUNowPlayingArtworkView()
		artworkView.activated = true
		artworkView.translatesAutoresizingMaskIntoConstraints = false
		artworkView.isUserInteractionEnabled = false
		containerView.addSubview(artworkView)

		labelsContainerView = UIView()
		labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(labelsContainerView)

		// steal the transport controls from MPUControlCenterMediaControlsViewController, which will
		// manage them for us
		controlsViewController = HaxMediaControlsViewController()
		let controlsView = controlsViewController.view!

		transportControls = controlsView.transportControls
		transportControls.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(transportControls)

		// TODO: property
		//let timeView = controlsView.value(forKey: "_timeView") as! UIView
		//timeView.translatesAutoresizingMaskIntoConstraints = false
		//containerView.addSubview(timeView)

		// also steal the labels
		titleLabel = controlsView.value(forKey: "_titleLabel") as! MPUControlCenterMetadataView
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(titleLabel)

		albumLabel = controlsView.value(forKey: "_albumLabel") as! MPUControlCenterMetadataView
		albumLabel.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(albumLabel)

		artistLabel = controlsView.value(forKey: "_artistLabel") as! MPUControlCenterMetadataView
		artistLabel.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(artistLabel)
		
		artistAlbumLabel = controlsView.value(forKey: "_artistAlbumConcatenatedLabel") as! MPUControlCenterMetadataView
		artistAlbumLabel.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(artistAlbumLabel)

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

		// sean spacer
		let spacerView = UIView()
		labelsContainerView.addSubview(spacerView)

		// do that auto layout stuff
		let isWidget = state != .notification

		let metrics: [String: NSNumber] = [
			"heightFactor": 0.4,
			"widgetHeight": 100,

			"margin": isWidget ? 8 : 14,
			"labelsContainerSpacing": 2,

			"labelSpacing": 4,
			"controlsMargin": 15,
			"controlsHeight": isWidget ? 38 : 44
		]

		let views: [String: UIView] = [
			"view": view,
			"containerView": containerView,

			"artworkView": artworkView,
			"labelsContainerView": labelsContainerView,
			"transportControls": transportControls,
			
			"titleLabel": titleLabel,
			"albumLabel": albumLabel,
			"artistLabel": artistLabel,
			"spacerView": spacerView
		]

		view.hb_addCompactConstraints([
			"containerView.top = self.top + margin",
			"containerView.leading = self.leading + margin",
			"containerView.trailing = self.trailing - margin",
			"containerView.bottom = self.bottom - margin"
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

			"labelsContainerView.top = self.top + labelsContainerSpacing",
			"labelsContainerView.leading = artworkView.trailing + margin",
			"labelsContainerView.trailing = self.trailing - margin",

			"transportControls.top = labelsContainerView.bottom",
			"transportControls.leading = labelsContainerView.leading + controlsMargin",
			"transportControls.trailing = labelsContainerView.trailing - controlsMargin / 2",
			"transportControls.bottom = self.bottom",
			"transportControls.height = controlsHeight"
		], metrics: metrics, views: views)

		labelsContainerView.hb_addCompactConstraints([
			"titleLabel.top = self.top",
			"titleLabel.leading = self.leading",
			"titleLabel.trailing = self.trailing",

			"albumLabel.top = titleLabel.bottom + labelSpacing",
			"albumLabel.leading = self.leading",
			"albumLabel.trailing = self.trailing",

			"artistLabel.top = albumLabel.bottom + labelSpacing",
			"artistLabel.leading = self.leading",
			"artistLabel.trailing = self.trailing",

			"spacerView.top = titleLabel.bottom + labelSpacing",
			"spacerView.leading = self.leading",
			"spacerView.trailing = self.trailing",
			"spacerView.bottom = self.bottom"
		], metrics: metrics, views: views)
		
		// set up the now playing controller to send us updates
		nowPlayingController = MPUNowPlayingController()
		nowPlayingController.delegate = self
		nowPlayingController.startUpdating()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let isSmall = state == .widgetCollapsed

		titleLabel.numberOfLines = isSmall ? 1 : 2
		titleLabel.marqueeEnabled = isSmall

		albumLabel.isHidden = isSmall
		artistLabel.isHidden = isSmall
		artistAlbumLabel.isHidden = !isSmall

		// the fuck is a greatestFiniteMagnitude? why wasn’t calling it “max”, like, you know, the
		// maximum number possible for the type, good enough?
		let size = CGSize(width: labelsContainerView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
		titleLabelHeightConstraint.constant = titleLabel.sizeThatFits(size).height
		albumLabelHeightConstraint.constant = albumLabel.sizeThatFits(size).height
		artistLabelHeightConstraint.constant = artistLabel.sizeThatFits(size).height
		artistAlbumLabelHeightConstraint.constant = artistAlbumLabel.sizeThatFits(size).height
	}

	// MARK: - Now playing

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, nowPlayingInfoDidChange info: [AnyHashable: Any]!) {
		artworkView.artworkImage = nowPlayingController.currentNowPlayingArtwork

		/*if nowPlayingController.nowPlayingAppDisplayID == nil {
			appNameLabel.text = ""
		} else {
			if let app = LSApplicationProxy(forIdentifier: nowPlayingController.nowPlayingAppDisplayID) {
				appNameLabel.text = app.localizedName.localizedUppercase
			}
		}*/

		view.setNeedsLayout()
	}

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, playbackStateDidChange state: Bool) {
		artworkView.setActivated(state, animated: true)
	}

	// MARK: - Public methods

	func setState(_ state: InterfaceState, animated: Bool) {
		self.state = state
		view.setNeedsLayout()
	}
	
}
