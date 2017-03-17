#import <Cephei/HBPreferences.h>

@interface HBCZPreferences : NSObject

+ (instancetype)sharedInstance;

@property (readonly) BOOL nowPlayingKeepBulletins, nowPlayingWakeWhenLocked, hideLockMusicControls;

@property (readonly) BOOL nowPlayingProvider;

- (void)registerPreferenceChangeBlock:(HBPreferencesChangeCallback)callback;

@end
