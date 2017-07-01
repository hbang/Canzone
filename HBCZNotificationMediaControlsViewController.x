#import "HBCZNotificationMediaControlsViewController.h"
#import <version.h>

%subclass HBCZNotificationMediaControlsViewController : MPUControlCenterMediaControlsViewController

- (CGSize)transportControlsView:(MPUControlCenterMediaControlsView *)view defaultTransportButtonSizeWithProposedSize:(CGSize)proposedSize {
	return CGSizeMake(28, 28);
}

/*- (UIButton *)transportControlsView:(MPUControlCenterMediaControlsView *)view buttonForControlType:(MPUTransportButtonType)type {
	UIButton *button = %orig;
	button.highlightedColor = [button.regularColor colorWithAlphaComponent:0.7f];
}*/

%end

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		%init;
	}
}
