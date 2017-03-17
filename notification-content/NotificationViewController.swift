import MobileCoreServices
import UIKit
import UserNotifications
import UserNotificationsUI

@objc(NotificationViewController)
class NotificationViewController: UIViewController, UNNotificationContentExtension, MPUNowPlayingDelegate {

	// we need to keep strong references around to these, otherwise they’d be released by ARC and we
	// don’t get to have the goodness they provide
	var nowPlayingController: MPUNowPlayingController!
	var controlsViewController: MPUControlCenterMediaControlsViewController!

	var artworkView: MPUNowPlayingArtworkView!
	var infoLabel: UILabel!
	var transportControls: UIView!
	
	// MARK: - View controller
	
	override func loadView() {
		super.loadView()

		view.translatesAutoresizingMaskIntoConstraints = false
		
		// construct the views
		// we disable user interaction on the artworkView as this allows touches to fall through to the
		// tap gesture recognizer in springboard, which will open the app
		artworkView = MPUNowPlayingArtworkView()
		artworkView.activated = true
		artworkView.translatesAutoresizingMaskIntoConstraints = false
		artworkView.isUserInteractionEnabled = false
		view.addSubview(artworkView)

		let labelsContainerView = UIView()
		labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(labelsContainerView)

		infoLabel = UILabel()
		infoLabel.translatesAutoresizingMaskIntoConstraints = false
		infoLabel.numberOfLines = 0
		labelsContainerView.addSubview(infoLabel)

		// steal the transport controls from MPUControlCenterMediaControlsViewController, which will
		// manage them for us
		controlsViewController = MPUControlCenterMediaControlsViewController()
		transportControls = controlsViewController.view.transportControls
		transportControls.translatesAutoresizingMaskIntoConstraints = false
		labelsContainerView.addSubview(transportControls)

		let metrics: [String: NSNumber] = [
			"outerMargin": 20,
			"innerMargin": 15,
			"labelSpacing": 4,
			"artworkSize": 151,
			"controlsMargin": 15,
			"transportControlsHeight": 44
		]

		let views: [String: UIView] = [
			"view": view,
			"artworkView": artworkView,
			"labelsContainerView": labelsContainerView,
			"infoLabel": infoLabel,
			"transportControls": transportControls
		]

		view.hb_addCompactConstraints([
			"artworkView.width = artworkSize",
			"artworkView.height = artworkSize",
			"artworkView.top = view.top + outerMargin",
			"artworkView.left = view.left + outerMargin",
			"artworkView.bottom = view.bottom - outerMargin",
			"labelsContainerView.left = artworkView.right + innerMargin",
			"labelsContainerView.right = view.right - outerMargin",
			"labelsContainerView.centerY = artworkView.centerY"
		], metrics: metrics, views: views)

		labelsContainerView.hb_addCompactConstraints([
			"infoLabel.top = self.top",
			"infoLabel.left = self.left",
			"infoLabel.right = self.right",
			"transportControls.top = infoLabel.bottom",
			"transportControls.left = self.left + controlsMargin",
			"transportControls.right = self.right + controlsMargin",
			"transportControls.bottom = self.bottom",
			"transportControls.height = transportControlsHeight"
		], metrics: metrics, views: views)

		nowPlayingController = MPUNowPlayingController()
		nowPlayingController.delegate = self
		nowPlayingController.startUpdating()
	}

	// MARK: - Now playing

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, nowPlayingInfoDidChange info: [AnyHashable: Any]!) {
		artworkView.artworkImage = nowPlayingController.currentNowPlayingArtwork

		let metadata = nowPlayingController.currentNowPlayingMetadata!

		infoLabel.text = "\(metadata.title ?? "")\n\(metadata.album ?? "")\n\(metadata.artist ?? "")"

		/*if nowPlayingController.nowPlayingAppDisplayID == nil {
			appNameLabel.text = ""
		} else {
			if let app = LSApplicationProxy(forIdentifier: nowPlayingController.nowPlayingAppDisplayID) {
				appNameLabel.text = app.localizedName.localizedUppercase
			}
		}*/
	}

	func nowPlayingController(_ nowPlayingController: MPUNowPlayingController!, playbackStateDidChange state: Bool) {
		artworkView.setActivated(state, animated: true)
	}
	
	// MARK: - Notification content
	
	func didReceive(_ notification: UNNotification) {
		// do nothing, just have to implement this to make the protocol happy
	}
	
}
