#import <BulletinBoard/BBDataProvider.h>

@class SBApplication;

@interface HBCZNowPlayingBulletinProvider : BBDataProvider <BBDataProvider>

+ (instancetype)sharedInstance;

- (void)postBulletinForApp:(SBApplication *)app title:(NSString *)title artist:(NSString *)artist album:(NSString *)album art:(NSData *)art;
- (void)clearAllBulletins;

@end
