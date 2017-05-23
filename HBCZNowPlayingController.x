#import "HBCZNowPlayingController.h"
#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZPreferences.h"
#import <MediaRemote/MediaRemote.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBMediaController.h>
#import <SpringBoard/SpringBoard.h>
#import <TypeStatusPlusProvider/HBTSPlusProvider.h>
#import <TypeStatusPlusProvider/HBTSPlusProviderController.h>

@implementation HBCZNowPlayingController {
	HBCZPreferences *_preferences;
	HBCZNowPlayingBulletinProvider *_bulletinProvider;

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
	self = [super init];

	if (self) {
		// set up variables
		_preferences = [HBCZPreferences sharedInstance];
		_bulletinProvider = [HBCZNowPlayingBulletinProvider sharedInstance];
		_lastSongIdentifier = @"";

		// listen for the now playing change notification
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mediaInfoDidChange:) name:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
	}

	return self;
}

#pragma mark - Notification callbacks

- (void)_mediaInfoDidChange:(NSNotification *)nsNotification {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.2), dispatch_get_main_queue(), ^{
		MRMediaRemoteGetNowPlayingInfo(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(CFDictionaryRef result) {
			// no really, why would you torture yourself and your clients by designing an api that uses
			// CF objects?
			NSDictionary *dictionary = (__bridge NSDictionary *)result;
			NSString *title = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
			NSString *artist = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
			NSString *album = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum];
			NSData *art = dictionary[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];

			// get the now playing app
			SBApplication *nowPlayingApp = ((SBMediaController *)[%c(SBMediaController) sharedInstance]).nowPlayingApplication;

			// no title or app? that’s weird. we can’t really do much without those things
			if (!title || !nowPlayingApp) {
				return;
			}

			// construct our internal identifier
			NSString *identifier = [NSString stringWithFormat:@"title = %@, artist = %@, album = %@", title, artist, album];
	
			// have we just shown one for this? ignore it
			if ([_lastSongIdentifier isEqualToString:identifier]) {
				return;
			}

			// store the identifier
			_lastSongIdentifier = identifier;

			// get the frontmost app
			SBApplication *frontmostApp = ((SpringBoard *)[UIApplication sharedApplication])._accessibilityFrontMostApplication;

			// if the now playing provider is enabled, and typestatus plus is present
			if (_preferences.nowPlayingProvider && %c(HBTSPlusProviderController)) {
				// as long as this isn’t coming from the frontmost app
				if (![frontmostApp.bundleIdentifier isEqualToString:nowPlayingApp.bundleIdentifier]) {
					// post it as a provider notification
					[self _postProviderNotificationForApp:nowPlayingApp title:title artist:artist];
				}
			} else {
				// else, post a bulletin
				[_bulletinProvider postBulletinForApp:nowPlayingApp title:title artist:artist album:album art:art];
			}
		});
	});
}

#pragma mark - TypeStatus Provider

- (void)_postProviderNotificationForApp:(SBApplication *)app title:(NSString *)title artist:(NSString *)artist {
	// if typestatus plus provider api isn’t available, don’t do anything
	if (!%c(HBTSPlusProviderController)) {
		return;
	}

	// construct a notification
	HBTSNotification *notification = [[%c(HBTSNotification) alloc] init];
	notification.content = artist ? [NSString stringWithFormat:@"%@ – %@", title, artist] : title;
	notification.boldRange = NSMakeRange(0, title.length);
	notification.statusBarIconName = @"TypeStatusPlusMusic";
	notification.sourceBundleID = app.bundleIdentifier;

	// grab our provider and show it
	HBTSPlusProvider *provider = [[%c(HBTSPlusProviderController) sharedInstance] providerWithAppIdentifier:kHBCZAppIdentifier];
	[provider showNotification:notification];
}

@end
