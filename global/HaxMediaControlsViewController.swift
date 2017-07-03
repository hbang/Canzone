import UIKit

class HaxMediaControlsViewController: MPUControlCenterMediaControlsViewController {

	var controlsHeight: CGFloat = 32

	func transportControlsView(_ view: UIView, defaultTransportButtonSizeWithProposedSize proposedSize: CGSize) -> CGSize {
		// force the buttons to be a little smaller. 38 is friggin huge
		return CGSize(width: controlsHeight, height: controlsHeight)
	}

	func _reloadDisplayModeOrCompactStyleVisibility() {
		// this messes up our stuff a bit, so override it to do nothing
	}

}
