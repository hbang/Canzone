import UIKit

class MetadataLabel: UIView {
	
	var attributedText: NSAttributedString {
		get {
			return label.attributedText
		}

		set {
			label.attributedText = newValue
			setNeedsLayout()
		}
	}

	var marqueeEnabled: Bool {
		get {
			return label.marqueeEnabled
		}

		set {
			label.marqueeEnabled = newValue
			setNeedsLayout()
		}
	}

	var numberOfLines: UInt {
		get {
			return label.numberOfLines
		}

		set {
			label.numberOfLines = newValue
			setNeedsLayout()
		}
	}

	private var label = MPUControlCenterMetadataView()

	// MARK: - Init

	override init(frame: CGRect) {
		super.init(frame: frame)

		isUserInteractionEnabled = false

		label.numberOfLines = 1
		label.marqueeEnabled = true
		addSubview(label)
	}

	required init(coder: NSCoder) {
		// shut up
		fatalError("")
	}

	// MARK: - View

	override func layoutSubviews() {
		super.layoutSubviews()

		// inset the label frame by 5pt on the left/right if marquee is disabled, to ensure consistency
		label.frame = bounds.insetBy(dx: marqueeEnabled ? 0 : 5, dy: 2)
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		// grab the value from the label and add 3 pixels as a margin
		var newSize = label.sizeThatFits(size)
		newSize.height += 3
		return newSize
	}

}
