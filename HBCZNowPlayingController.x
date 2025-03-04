#import "HBCZNowPlayingController.h"
#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZPreferences.h"
#import <MediaRemote/MediaRemote.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBMediaController.h>
#import <SpringBoard/SpringBoard.h>
#import <TypeStatusPlusProvider/HBTSPlusProvider.h>
#import <TypeStatusPlusProvider/HBTSPlusProviderController.h>
#import <UIKit/UIImage+Private.h>

@implementation HBCZNowPlayingController {
	HBCZPreferences *_preferences;
	HBCZNowPlayingBulletinProvider *_bulletinProvider;

	NSData *_placeholderArtData;
	NSString *_lastSongIdentifier;
}

+ (instancetype)sharedInstance {
	static HBCZNowPlayingController *sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

#pragma mark - NSObject

- (instancetype)init {
	if (!IN_SPRINGBOARD) {
		return nil;
	}

	self = [super init];

	if (self) {
		// set up variables
		_preferences = [HBCZPreferences sharedInstance];
		_bulletinProvider = [HBCZNowPlayingBulletinProvider sharedInstance];
		_lastSongIdentifier = @"";

		// listen for the now playing change notification
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mediaInfoDidChange:) name:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];

		// grab the fallback placeholder artwork image
		NSBundle *mpuiBundle = [NSBundle bundleWithIdentifier:@"com.apple.MediaPlayerUI"];
		UIImage *placeholderImage = [UIImage imageNamed:@"placeholder-artwork" inBundle:mpuiBundle];
		_placeholderArtData = UIImagePNGRepresentation(placeholderImage);
	}

	return self;
}

#pragma mark - Notification callbacks

- (void)_mediaInfoDidChange:(NSNotification *)nsNotification {
	// hack: wait 200ms for art to hopefully be there for us
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.2), dispatch_get_main_queue(), ^{
		MRMediaRemoteGetNowPlayingInfo(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(CFDictionaryRef result) {
			// no really, why would you torture yourself and your clients by designing an api that uses
			// CF objects?
			NSDictionary *dictionary = (__bridge NSDictionary *)result;
			NSString *title = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
			NSString *artist = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
			NSString *album = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum];
			NSData *art = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData] ?: _placeholderArtData;

			// get the now playing app
			SBApplication *nowPlayingApp = ((SBMediaController *)[%c(SBMediaController) sharedInstance]).nowPlayingApplication;

			// no title or app? that’s weird. we can’t really do much without those things
			if (!title || !nowPlayingApp) {
				return;
			}

			// construct our internal identifier
			NSString *identifier = [NSString stringWithFormat:@"title = %@, artist = %@, album = %@", title, artist, album];
	
			// have we just shown one for this?
			if ([_lastSongIdentifier isEqualToString:identifier]) {
				// the art could have changed. post a notification for it
				[[NSNotificationCenter defaultCenter] postNotificationName:HBCZNowPlayingArtworkChangedNotification object:nil userInfo:@{
					@"identifier": identifier,
					@"artwork": art
				}];
			} else {
				// store the identifier
				_lastSongIdentifier = identifier;

				// post the bulletin
				[_bulletinProvider postBulletinForApp:nowPlayingApp title:title artist:artist album:album art:art];
			}
		});
	});
}

@end
