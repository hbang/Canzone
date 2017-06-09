#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZNowPlayingController.h"
#import "HBCZPreferences.h"
#import <BulletinBoard/BBLocalDataProviderStore.h>
#import <UserNotificationsUIKit/NCNotificationViewController.h>
#import <SpringBoard/SBMediaController.h>
#import <UIKit/UIView+Private.h>


@interface NCNotificationRequest : NSObject // UNUIKit

@property (nonatomic, copy, readonly) NSString *sectionIdentifier;

@end

@interface NCNotificationExtensionContainerViewController : UIViewController

@property (nonatomic) BOOL userInteractionEnabled;

@end


#pragma mark - Variables

HBCZPreferences *preferences;

#pragma mark - Notification Center

%hook BBLocalDataProviderStore

- (void)loadAllDataProvidersAndPerformMigration:(BOOL)performMigration {
	%orig;

	// add ourself as a data provider
	[self addDataProvider:[HBCZNowPlayingBulletinProvider sharedInstance] performMigration:YES];
}

%end

#pragma mark - Hide banner in foreground app

%hook SBApplication

- (BOOL)shouldSuppressAlertForSuppressionContexts:(id)suppressionContexts sectionIdentifier:(NSString *)sectionIdentifier {
	// if this is a bulletin coming from our section, and we’re inside the now playing app, indicate
	// to not show the alert (banner)
	if ([sectionIdentifier isEqualToString:kHBCZAppIdentifier] && ((SBMediaController *)[%c(SBMediaController) sharedInstance]).nowPlayingApplication == self) {
		return YES;
	}

	return %orig;
}

%end

#pragma mark - Hide now playing controls

%hook SBLockScreenNowPlayingController

- (void)_updateToState:(long long)state {
	// TODO: work out the enum values
	// but basically, anything over 2 is “enabled”, 0 and 1 are “disabled” in some way
	%orig(preferences.hideLockMusicControls && state > 1 ? 0 : state);
}

%end

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

@interface NCNotificationContentView : UIView

- (BOOL)_hb_isCanzoneNotification;

@end

%hook NCNotificationContentView

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
	}

	return newFrame;
}

%end

#pragma mark - Constructor

%ctor {
	// set up variables
	preferences = [HBCZPreferences sharedInstance];

	// get the controller rolling
	[HBCZNowPlayingController sharedInstance];
}
