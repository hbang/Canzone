import UIKit

class HaxMediaControlsViewController: MPUControlCenterMediaControlsViewController {

	func transportControlsView(_ view: UIView, defaultTransportButtonSizeWithProposedSize proposedSize: CGSize) -> CGSize {
		// force the buttons to be a little smaller. 38 is friggin huge
		return CGSize(width: 32, height: 32)
	}

}
