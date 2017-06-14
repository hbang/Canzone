#import "HBCZNotificationMediaControlsViewController.h"
#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZNowPlayingController.h"
#import <MediaPlayerUI/MPUTransportControlsView.h>
#import <MediaPlayerUI/MPUNowPlayingArtworkView.h>
#import <UserNotificationsUIKit/NCNotificationViewController.h>
#import <UIKit/UIView+Private.h>
#import <version.h>

#pragma mark - This should not be here lol

@interface NCNotificationContentView : UIView

- (UIImageView *)_lazyThumbnailImageView;

- (BOOL)_hb_isCanzoneNotification;

@property (nonatomic, retain) UIView *accessoryView;

@property (nonatomic, retain) HBCZNotificationMediaControlsViewController *hb_canzoneControlsViewController;
@property (nonatomic, retain) MPUTransportControlsView *hb_canzoneControlsView;
@property (nonatomic, retain) MPUNowPlayingArtworkView *hb_canzoneArtworkView;

@end

@interface NCNotificationRequest : NSObject // UNKit

@property (nonatomic, copy, readonly) NSString *sectionIdentifier;

@end

@interface NCNotificationExtensionContainerViewController : UIViewController

@property (nonatomic) BOOL userInteractionEnabled;

@end

#pragma mark - Enable user interaction

%hook NCNotificationExtensionContainerViewController

- (instancetype)initWithExtension:(id)extension forNotificationRequest:(NCNotificationRequest *)request {
	self = %orig;

	if (self) {
		// if this is us, override and allow touches to be sent through to our remote view
		if ([request.sectionIdentifier isEqualToString:kHBCZAppIdentifier]) {
			self.userInteractionEnabled = YES;
		}
	}

	return self;
}

%end

#pragma mark - Notification UI

%hook NCNotificationContentView

%property (nonatomic, retain) HBCZNotificationMediaControlsViewController *hb_canzoneControlsViewController;
%property (nonatomic, retain) MPUTransportControlsView *hb_canzoneControlsView;

%new - (BOOL)_hb_isCanzoneNotification {
	NCNotificationViewController *viewController = (NCNotificationViewController *)self._viewControllerForAncestor;

	if ([viewController isKindOfClass:%c(NCNotificationViewController)]) {
		NCNotificationRequest *request = viewController.notificationRequest;
		return request && [request.sectionIdentifier isEqualToString:kHBCZAppIdentifier];
	} else {
		return NO;
	}
}

- (BOOL)_shouldReverseLayoutDirection {
	return self._hb_isCanzoneNotification ? YES : %orig;
}

- (CGRect)_frameForThumbnailInRect:(CGRect)rect {
	CGRect newFrame = %orig;

	if (self._hb_isCanzoneNotification) {
		newFrame.origin.y -= 4.f;
		newFrame.size.width += 4.f;
		newFrame.size.height += 4.f;
	}

	return newFrame;
}

- (void)layoutSubviews {
	BOOL isCanzoneNotification = self._hb_isCanzoneNotification;

	if (isCanzoneNotification) {
		HBCZNotificationMediaControlsViewController *viewController = self.hb_canzoneControlsViewController;
		MPUTransportControlsView *controlsView = self.hb_canzoneControlsView;

		if (!viewController) {
			viewController = [[%c(HBCZNotificationMediaControlsViewController) alloc] init];
			self.hb_canzoneControlsViewController = viewController;
		}

		if (!controlsView) {
			controlsView = viewController.view.transportControls;
			controlsView.alpha = 0.9f;
			controlsView.minimumNumberOfTransportButtonsForLayout = 2;
			controlsView.frame = CGRectMake(self.frame.size.width - 100.f - 15.f, 0, 100.f, self.frame.size.height);
			controlsView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
			[self addSubview:controlsView];
			
			self.hb_canzoneControlsView = controlsView;
		}

		controlsView.hidden = NO;
	} else {
		self.hb_canzoneControlsView.hidden = YES;
	}

	%orig;

	if (isCanzoneNotification) {
		UIView *contentView = [self valueForKey:@"_contentView"];

		// TODO: something not as stupid as this!!!
		contentView.clipsToBounds = YES;

		CGRect contentFrame = contentView.frame;
		contentFrame.size.width -= 115.f;
		contentView.frame = contentFrame;
	}
}

%end

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		%init;
	}
}
