#import "HBCZNotificationListCell.h"
#import "HBCZNotificationWidgetViewController.h"
#import "HBCZPreferences.h"
#import <version.h>

@interface NCNotificationRequest : NSObject // UNKit

@property (nonatomic, copy, readonly) NSString *sectionIdentifier;

@end

@interface NCNotificationRequest ()

- (BOOL)hb_isCanzoneNotification;

@end

@interface NCNotificationContentView : UIView

@property (nonatomic, retain, setter=hb_setWidgetView:) UIView *hb_widgetView;

@end

HBCZPreferences *preferences;

%subclass HBCZNotificationListCell : NCNotificationListCell

%property (nonatomic, retain) HBCZNotificationWidgetViewController *hb_canzoneWidgetViewController;

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize newSize = %orig;
	newSize.height += 30;
	return newSize;
}

- (void)updateCellForContentViewController:(UIViewController *)viewController {
	%orig;

	HBCZNotificationWidgetViewController *widgetViewController = self.hb_canzoneWidgetViewController;
	NCNotificationContentView *contentView = [self.contentViewController._lookViewIfLoaded valueForKey:@"_notificationContentView"];

	if (preferences.showBannerControls) {
		if (!widgetViewController) {
			widgetViewController = [[%c(HBCZNotificationWidgetViewController) alloc] init];
			[widgetViewController willMoveToParentViewController:viewController];
			widgetViewController.view.frame = contentView.bounds;
			widgetViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			contentView.hb_widgetView = widgetViewController.view;

			self.hb_canzoneWidgetViewController = widgetViewController;
		}

		// i just... i spent about a day on this i don't really care right now
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5), dispatch_get_main_queue(), ^{
			[contentView sizeToFit];
			[self setNeedsLayout];
		});
	} else {
		// get rid of the view controller if we're not needed
		[widgetViewController willMoveToParentViewController:nil];
		contentView.hb_widgetView = nil;
		[widgetViewController removeFromParentViewController];

		widgetViewController = nil;
		self.hb_canzoneWidgetViewController = nil;
	}
}

%end

#pragma mark - Constructor

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		preferences = [HBCZPreferences sharedInstance];

		%init;
	}
}
