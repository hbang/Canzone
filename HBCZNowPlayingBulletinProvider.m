#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZNowPlayingController.h"
#import "HBCZPreferences.h"
#import <BulletinBoard/BBAction.h>
#import <BulletinBoard/BBAppearance.h>
#import <BulletinBoard/BBBulletinRequest.h>
#import <BulletinBoard/BBDataProviderIdentity.h>
#import <BulletinBoard/BBSectionInfo.h>
#import <BulletinBoard/BBSectionParameters.h>
#import <BulletinBoard/BBSectionSubtypeParameters.h>
#import <BulletinBoard/BBServer.h>
#import <BulletinBoard/BBThumbnailSizeConstraints.h>
#import <SpringBoard/SBApplication.h>

NSString *const kHBCZNowPlayingSubsectionIdentifier = @"ws.hbang.canzone.nowplayingsection";
static NSString *const kHBCZNowPlayingLockSubsectionIdentifier = @"ws.hbang.canzone.nowplayinglocksection";
static NSString *const kHBCZNowPlayingBulletinRecordIdentifier = @"ws.hbang.canzone.nowplaying";
static NSString *const kHBCZNowPlayingCategoryIdentifier = @"CanzoneNowPlayingCategory";

@interface BBSectionSubtypeParameters ()

@property (nonatomic, copy) NSString *alternateActionLabel;
@property (nonatomic, copy) NSString *secondaryContentRemoteServiceBundleIdentifier;
@property (nonatomic, copy) NSString *secondaryContentRemoteViewControllerClassName;

@end

@implementation HBCZNowPlayingBulletinProvider {
	HBCZPreferences *_preferences;

	UIImage *_currentArt;
	NSMutableSet <BBBulletinRequest *> *_sentBulletins;
}

#pragma mark - Singleton

+ (instancetype)sharedInstance {
	static HBCZNowPlayingBulletinProvider *sharedInstance;
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
		_currentArt = nil;
		_sentBulletins = [NSMutableSet setWithCapacity:1];

		// construct our data provider identity
		BBDataProviderIdentity *identity = [BBDataProviderIdentity identityForDataProvider:self];

		// give it our identifier and name
		identity.sectionIdentifier = kHBCZAppIdentifier;
		identity.sectionDisplayName = @"Now Playing"; // TODO: localize

		// set ourself as only displaying alerts, not sounds or badges
		identity.defaultSectionInfo.pushSettings = BBSectionInfoPushSettingsAlerts;

		// make up our subsection and set them
		BBSectionInfo *mainSubsection = [BBSectionInfo defaultSectionInfoForType:2];
		mainSubsection.sectionID = identity.sectionIdentifier;
		mainSubsection.subsectionID = kHBCZNowPlayingSubsectionIdentifier;

		identity.defaultSubsectionInfos = @[ mainSubsection ];

		// construct our default subtype parameters
		BBSectionSubtypeParameters *subtypeParameters = identity.sectionParameters.defaultSubtypeParameters;
		subtypeParameters.secondaryContentRemoteServiceBundleIdentifier = @"ws.hbang.canzone.app.notificationcontent";
		subtypeParameters.secondaryContentRemoteViewControllerClassName = @"NotificationViewController";
		subtypeParameters.allowsAddingToLockScreenWhenUnlocked = YES;
		subtypeParameters.allowsAutomaticRemovalFromLockScreen = NO;
		subtypeParameters.prioritizeAtTopOfLockScreen = YES;
		
		// construct our “replace lock media controls” subtype
		BBSectionSubtypeParameters *lockParameters = [[BBSectionSubtypeParameters alloc] init];

		identity.sectionParameters.allSubtypeParameters = [@{
			@2: lockParameters
		} mutableCopy];

		self.identity = identity;
	}

	return self;
}

#pragma mark - Post bulletin

- (void)postBulletinForApp:(SBApplication *)app title:(NSString *)title artist:(NSString *)artist album:(NSString *)album art:(NSData *)art {
	// if we need to pull the previous bulletins, do that first
	if (!_preferences.nowPlayingKeepBulletins) {
		[self clearAllBulletins];
	}

	// construct our bulletin
	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];

	// set the basic stuff
	bulletin.bulletinID = [NSUUID UUID].UUIDString;
	bulletin.sectionID = kHBCZAppIdentifier;
	bulletin.categoryID = kHBCZNowPlayingCategoryIdentifier;

	// set the record id based on the keep all bulletins setting
	bulletin.recordID = bulletin.bulletinID;

	// set the subsection based on the hide music controls setting
	bulletin.subsectionIDs = [NSSet setWithObject:_preferences.hideLockMusicControls ? kHBCZNowPlayingLockSubsectionIdentifier : kHBCZNowPlayingSubsectionIdentifier];

	// set the text fields
	bulletin.title = title;

	// if we have an album and artist, have them both separated by newline. otherwise, use whichever
	// of the two exists (or none!)
	if (album && artist) {
		bulletin.message = [NSString stringWithFormat:@"%@\n%@", album, artist];
	} else {
		bulletin.message = album ?: artist;
	}

	// set all the rest
	bulletin.date = [NSDate date];
	bulletin.lastInterruptDate = bulletin.date;
	bulletin.turnsOnDisplay = _preferences.nowPlayingWakeWhenLocked;
	bulletin.primaryAttachmentType = BBAttachmentMetadataTypeImage;

	// set a callback to open the app
	bulletin.defaultAction = [BBAction actionWithLaunchBundleID:app.bundleIdentifier callblock:nil];

	// on apple watch, launch NanoNowPlaying
	// TODO: this doesn’t work :( maybe we’ll have to go back to the phone, then have the phone tell
	// the watch to open the app
	BBAction *watchAction = [BBAction actionWithAppearance:[BBAppearance appearanceWithTitle:@"Open"]];
	watchAction.identifier = @"open-on-watch";
	watchAction.callblock = ^{ HBLogWarn(@"watch out bitchezz"); };
	
	// set all our supplementary actions
	bulletin.supplementaryActionsByLayout = @{
		@1: @[ watchAction ]
	};

	// get a UIImage of the art and hold onto it
	_currentArt = [[UIImage alloc] initWithData:art];

	// send it!
	BBDataProviderAddBulletin(self, bulletin);
	[_sentBulletins addObject:bulletin];
}

- (void)clearAllBulletins {
	// loop and remove all notifications we’ve sent
	for (BBBulletinRequest *bulletin in _sentBulletins) {
		BBDataProviderWithdrawBulletinsWithRecordID(self, bulletin.recordID);
	}

	// empty the set
	[_sentBulletins removeAllObjects];
}

#pragma mark - BBDataProvider

- (NSArray *)sortDescriptors {
	return @[ [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO] ];
}

- (NSData *)attachmentPNGDataForRecordID:(NSString *)recordID sizeConstraints:(BBThumbnailSizeConstraints *)constraints {
	// return the current item’s album art. this is only called once when the bulletin is being
	// prepared for display; after that it’s stored, well, somewhere

	// no art? nothing for us to do
	if (!_currentArt) {
		return nil;
	}

	// determine the size to use
	CGSize size = [constraints sizeFromAspectRatio:1];

	// render at the new size
	UIGraphicsBeginImageContextWithOptions(size, NO, 0);
	[_currentArt drawInRect:(CGRect){ CGPointZero, size }];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	// turn it back into a png and return it
	return UIImagePNGRepresentation(newImage);
}

@end
