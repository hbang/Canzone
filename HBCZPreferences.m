#import "HBCZPreferences.h"

@implementation HBCZPreferences {
	HBPreferences *_preferences;
}

+ (instancetype)sharedInstance {
	static HBCZPreferences *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_preferences = [[HBPreferences alloc] initWithIdentifier:@"ws.hbang.canzone"];

		[_preferences registerBool:&_nowPlayingKeepBulletins default:NO forKey:@"NowPlayingKeepBulletins"];
		[_preferences registerBool:&_nowPlayingWakeWhenLocked default:NO forKey:@"NowPlayingWakeWhenLocked"];
		[_preferences registerBool:&_hideLockMusicControls default:YES forKey:@"HideLockMusicControls"];
		[_preferences registerBool:&_showBannerControls default:YES forKey:@"BannerControls"];

		[_preferences registerBool:&_nowPlayingProvider default:NO forKey:@"NowPlayingProvider"];
	}

	return self;
}

- (void)registerPreferenceChangeBlock:(HBPreferencesChangeCallback)callback {
	[_preferences registerPreferenceChangeBlock:callback];
}

@end
