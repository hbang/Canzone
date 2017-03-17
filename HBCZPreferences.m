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

		// if typestatus plus is installed, enable the provider and disable hiding lock music controls
		// by default
		if (!_preferences[@"NowPlayingProvider"]) {
			BOOL hasTypeStatusPlus = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/TypeStatusPlus.dylib"];

			_preferences[@"NowPlayingProvider"] = @(hasTypeStatusPlus);
			_preferences[@"HideLockMusicControls"] = @(!hasTypeStatusPlus);
		}

		[_preferences registerBool:&_nowPlayingKeepBulletins default:NO forKey:@"NowPlayingKeepBulletins"];
		[_preferences registerBool:&_nowPlayingWakeWhenLocked default:NO forKey:@"NowPlayingWakeWhenLocked"];
		[_preferences registerBool:&_hideLockMusicControls default:YES forKey:@"HideLockMusicControls"];

		[_preferences registerBool:&_nowPlayingProvider default:YES forKey:@"NowPlayingProvider"];
	}

	return self;
}

- (void)registerPreferenceChangeBlock:(HBPreferencesChangeCallback)callback {
	[_preferences registerPreferenceChangeBlock:callback];
}

@end
