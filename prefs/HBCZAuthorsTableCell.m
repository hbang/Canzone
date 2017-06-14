#import "HBCZAuthorsTableCell.h"

@implementation HBCZAuthorsTableCell {
	UITextView *_textView;
}

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
	self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil specifier:specifier];

	if (self) {
		self.backgroundColor = nil;

		// construct an attributed string
		NSString *text = NSLocalizedStringFromTableInBundle(@"AUTHORS_LABEL", @"About", [NSBundle bundleForClass:self.class], @"");

		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.alignment = NSTextAlignmentCenter;

		NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
			NSFontAttributeName: [UIFont systemFontOfSize:14.f],
			NSForegroundColorAttributeName: [UIColor colorWithWhite:40.f / 255.f alpha:1],
			NSBaselineOffsetAttributeName: @(6.f),
			NSParagraphStyleAttributeName: paragraphStyle,
		}];

		// set up the links
		[attributedString addAttributes:@{
			NSLinkAttributeName: [NSURL URLWithString:@"https://twitter.com/tmnlsthrn"]
		} range:[text rangeOfString:@"Timon Olsthoorn"]];

		[attributedString addAttributes:@{
			NSLinkAttributeName: [NSURL URLWithString:@"http://kirb.me/"]
		} range:[text rangeOfString:@"Adam Demasi"]];

		// instantiate and add a text view with the attributed string
		_textView = [[UITextView alloc] initWithFrame:self.contentView.bounds];
		_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_textView.backgroundColor = nil;
		_textView.attributedText = attributedString;
		_textView.editable = NO;
		_textView.scrollEnabled = NO;
		[self.contentView addSubview:_textView];
	}

	return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
	return ceilf([_textView sizeThatFits:CGSizeMake(width - 30.f, CGFLOAT_MAX)].height);
}

@end
