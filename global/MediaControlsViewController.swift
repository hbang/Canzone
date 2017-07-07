import MobileCoreServices
import UIKit

class MediaControlsViewController: UIViewController, MPUNowPlayingDelegate {

	enum InterfaceState: UInt {
		case widgetCollapsed, widgetExpanded
		case notification
	}

	// we need to keep strong references to these around, otherwise they’d be released by ARC and we
	// don’t get to have the goodness they provide
	var nowPlayingController = MPUNowPlayingController()
	var controlsViewController = HaxMediaControlsViewController()

	var containerView = UIView()
	var artworkView = MPUNowPlayingArtworkView()
	var labelsContainerView = UIView()

	var titleLabel = MetadataLabel(frame: .zero)
	var artistAlbumLabel = MetadataLabel(frame: .zero)
	
	var transportControls: UIView {
		return controlsViewController.view!.transportControls
	}

	var titleLabelHeightConstraint: NSLayoutConstraint!
	var artistAlbumLabelHeightConstraint: NSLayoutConstraint!

	var state = InterfaceState.notification {
		didSet { updateMetadata() }
	}

	lazy var mpuiBundle = Bundle(identifier: "com.apple.MediaPlayerUI")!

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

		// set up the now playing controller to send us updates
		nowPlayingController.delegate = self

		let isWidget = state != .notification

		view.autoresizingMask = [ .flexibleWidth ]

		// construct the views
		containerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(containerView)

		artworkView.translatesAutoresizingMaskIntoConstraints = false
		artworkView.activated = true
		artworkView.addTarget(self, action: #selector(self.artworkTapped), for: .touchUpInside)
		containerView.addSubview(artworkView)

		labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(labelsContainerView)

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(titleLabel)

		artistAlbumLabel.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(artistAlbumLabel)

		// steal the transport controls from MPUControlCenterMediaControlsViewController, which will
		// manage them for us
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
				"artworkView.bottom = containerView.bottom - artworkInset",
				"labelsContainerView.top = containerView.top",
				"labelsContainerView.bottom = containerView.bottom"
			], metrics: metrics, views: views)
		}

		containerView.hb_addConstraints(withVisualFormat: "H:|-artworkInset-[artworkView\(isWidget ? "(widgetArtworkSize)" : "")]-innerMargin-[labelsContainerView]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)
		labelsContainerView.hb_addConstraints(withVisualFormat: "V:|[titleLabel][artistAlbumLabel][spacerView][transportControls(controlsHeight)]|", options: NSLayoutFormatOptions(), metrics: metrics, views: views)

		// is there not a better, concise way to do this??
		labelsContainerView.hb_addCompactConstraints([
			"titleLabel.leading = self.leading", "titleLabel.trailing = self.trailing",
			"artistAlbumLabel.leading = self.leading", "artistAlbumLabel.trailing = self.trailing",
			"spacerView.leading = self.leading", "spacerView.trailing = self.trailing",

			"transportControls.width = controlsWidth",
			"transportControls.centerX = labelsContainerView.centerX"
		], metrics: metrics, views: views)

		// manually make some constraints for the label heights
		titleLabelHeightConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		artistAlbumLabelHeightConstraint = NSLayoutConstraint(item: artistAlbumLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
		
		labelsContainerView.addConstraints([
			titleLabelHeightConstraint,
			artistAlbumLabelHeightConstraint
		])
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		nowPlayingController.startUpdating()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		nowPlayingController.stopUpdating()
	}

	override func viewWillLayoutSubviews() {
		let isSmall = state == .widgetCollapsed

		super.viewWillLayoutSubviews()

		// set the right number of lines and marquee state on the labels
		titleLabel.numberOfLines = isSmall ? 1 : 2
		artistAlbumLabel.numberOfLines = isSmall ? 1 : 2

		titleLabel.marqueeEnabled = isSmall
		artistAlbumLabel.marqueeEnabled = isSmall

		// the fuck is a greatestFiniteMagnitude? why wasn’t calling it “max”, like, you know, the
		// maximum number possible for the type, good enough?
		let size = CGSize(width: labelsContainerView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
		titleLabelHeightConstraint.constant = titleLabel.sizeThatFits(size).height
		artistAlbumLabelHeightConstraint.constant = artistAlbumLabel.sizeThatFits(size).height
	}

	func updateMetadata() {
		// get the artwork, falling back on MPUI's placeholder image (usually when we're not playing)
		let artworkImage = nowPlayingController.currentNowPlayingArtwork ?? UIImage(named: "placeholder-artwork", in: mpuiBundle)

		// if the artwork changed, update it
		if artworkView.artworkImage != artworkImage {
			artworkView.artworkImage = artworkImage
		}

		guard let metadata = nowPlayingController.currentNowPlayingMetadata else {
			return
		}

		// for some reason, this starts off being nil and calling it causes it to be populated, which
		// we'll need to open the app if the artwork view is tapped
		_ = nowPlayingController.nowPlayingAppDisplayID

		// set the labels to something useful
		let attributes = [
			NSFontAttributeName: UIFont.preferredFont(forTextStyle: .body),
			NSForegroundColorAttributeName: UIColor.black
		]

		titleLabel.attributedText = NSAttributedString(string: metadata.title ?? "", attributes: attributes)

		var subtitleText = ""

		if metadata.album != nil && metadata.artist != nil {
			// construct a subtitle based on the format string MPUI uses
			subtitleText = String(format: NSLocalizedString("ARTIST_ALBUM_CONCATENATED_FORMAT", tableName: "MediaPlayerUI", bundle: mpuiBundle, comment: ""), metadata.album!, metadata.artist)
		} else if metadata.album != nil {
			subtitleText = metadata.album!
		} else if metadata.artist != nil {
			subtitleText = metadata.artist!
		}

		artistAlbumLabel.attributedText = NSAttributedString(string: subtitleText, attributes: attributes)

		// the layout needs updating now
		view.setNeedsLayout()

		if let app = LSApplicationProxy(forIdentifier: nowPlayingController.nowPlayingAppDisplayID) {
			title = app.localizedName
		}
	}

	// MARK: - Now playing

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, nowPlayingInfoDidChange info: [AnyHashable: Any]!) {
		updateMetadata()
	}

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, playbackStateDidChange state: Bool) {
		artworkView.setActivated(state, animated: true)
	}

	// MARK: - Callbacks

	func artworkTapped() {
		guard let bundleID = nowPlayingController.nowPlayingAppDisplayID else {
			// nothing playing, probably. nothing to do here
			return
		}

		// launch the app, hopefully
		LSApplicationWorkspace.default().openApplication(withBundleID: bundleID)
	}
	
}
