#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZNowPlayingController.h"
#import <BulletinBoard/BBLocalDataProviderStore.h>

#pragma mark - Notification Center

%hook BBLocalDataProviderStore

- (void)loadAllDataProvidersAndPerformMigration:(BOOL)performMigration {
	%orig;

	// add ourself as a data provider
	[self addDataProvider:[HBCZNowPlayingBulletinProvider sharedInstance] performMigration:YES];
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
	// get the controller rolling
	[HBCZNowPlayingController sharedInstance];
}
