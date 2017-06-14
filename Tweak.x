#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZNowPlayingController.h"
#import "HBCZPreferences.h"
#import <BulletinBoard/BBLocalDataProviderStore.h>
#import <SpringBoard/SBMediaController.h>
#import <version.h>

@interface NCNotificationRequest : NSObject // UNKit

@property (nonatomic, copy, readonly) NSString *sectionIdentifier;

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

#pragma mark - Constructor

%ctor {
	// set up variables
	preferences = [HBCZPreferences sharedInstance];

	// get the controller rolling
	[HBCZNowPlayingController sharedInstance];
}
