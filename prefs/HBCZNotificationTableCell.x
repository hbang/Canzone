#import "HBCZNotificationTableCell.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIImage+Private.h>
#include <dlfcn.h>

@interface NCNotificationContent : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, readonly, copy) NSString *header;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *message;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly, copy) NSString *topic;

@property (nonatomic, readonly) NSDate *date;
@property (getter=isDateAllDay, nonatomic, readonly) BOOL dateAllDay;
@property (nonatomic, readonly) NSTimeZone *timeZone;

@property (nonatomic, readonly) UIImage *icon;
@property (nonatomic, readonly) UIImage *attachmentImage;

@end

@interface NCMutableNotificationContent : NCNotificationContent

@property (nonatomic, copy) NSString *header;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *topic;

@property (nonatomic, retain) NSDate *date;
@property (getter=isDateAllDay, nonatomic) BOOL dateAllDay;
@property (nonatomic, retain) NSTimeZone *timeZone;

@property (nonatomic, retain) UIImage *icon;
@property (nonatomic, retain) UIImage *attachmentImage;

@end

@interface NCNotificationRequest : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, copy, readonly) NSString *sectionIdentifier;

@property (nonatomic, retain, readonly) NCNotificationContent *content;

@end

@interface NCMutableNotificationRequest : NSObject

@property (nonatomic, copy) NSString *sectionIdentifier;

@property (nonatomic, retain) NCMutableNotificationContent *content;

@end

@interface NCNotificationViewController : UIViewController

- (instancetype)initWithNotificationRequest:(NCNotificationRequest *)request;

@property (nonatomic, retain) UIView *associatedView;

@end

@interface NCNotificationListCell : UICollectionViewCell

@property (nonatomic, assign) BOOL configured;
@property (nonatomic, assign) BOOL backgroundBlurred;
@property (nonatomic, assign) BOOL adjustsFontForContentSizeCategory;
@property (nonatomic, assign) UIEdgeInsets insetMargins;

@property (nonatomic, retain) NCNotificationViewController *contentViewController;

@end

@implementation HBCZNotificationTableCell {
	NCNotificationListCell *_notificationCell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.backgroundColor = [UIColor blackColor];

		UIImageView *wallpaperView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
		wallpaperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		wallpaperView.image = [UIImage imageWithContentsOfCPBitmapFile:@"~/Library/SpringBoard/LockBackground.cpbitmap".stringByExpandingTildeInPath flags:kNilOptions];
		wallpaperView.contentMode = UIViewContentModeScaleAspectFill;
		wallpaperView.clipsToBounds = YES;
		wallpaperView.layer.minificationFilter = kCAFilterTrilinear;
		[self.contentView addSubview:wallpaperView];

		[self _setUpNotification];
	}

	return self;
}

- (void)_setUpNotification {
	static NSArray *Songs;
	static UIImage *CanzoneImage;
	static UIImage *PlaceholderImage;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/UserNotificationsUIKit.framework"] load];
		dlopen("/Library/MobileSubstrate/DynamicLibraries/Canzone.dylib", RTLD_LAZY);

		Songs = @[
			@[ @"Take on Me", @"Hunting High and Low\na-ha" ],
			@[ @"Get Lucky", @"Random Access Memories\nDaft Punk" ],
			@[ @"Drop It Like It’s Hot", @"R&G (Rhythm & Gangsta): The Masterpiece\nSnoop Dogg ft. Pharrell" ],
			@[ @"Every Teardrop is a Waterfall", @"Until Now\nColdplay vs Swedish House Mafia" ],
			@[ @"Satellite", @"Sirens of the Sea\nOceanlab" ],
			@[ @"What Is Love", @"The Album\nHaddaway" ],
			@[ @"All Star", @"All Star Smash Hits\nSmash Mouth" ],
			@[ @"Sandstorm", @"Before the Storm\nDarude" ],
			@[ @"Secret Agent", @"Netsky\nNetsky" ],
			@[ @"Strobe", @"For Lack Of A Better Name\ndeadmau5" ],
			@[ @"Slam The Door", @"Slam The Door\nZedd" ],
			@[ @"Till The Sky Falls Down", @"The New Daylight\nDash Berlin" ],
			@[ @"Deep At Night (Adam K & Soha Remix)", @"Deep At Night\nErcola & Heikki L" ],
			@[ @"Snowcone", @"W:/2016ALBUM/\ndeadmau5" ],
			@[ @"Kyoto", @"Horsestep\nDJ Sn0w & DJ Horse" ]
		];

		CanzoneImage = [UIImage _applicationIconImageForBundleIdentifier:@"ws.hbang.canzone.app" format:MIIconVariantDocumentSmall scale:[UIScreen mainScreen].scale]; // yeah the names are messed up
		PlaceholderImage = [UIImage imageNamed:@"placeholder-artwork" inBundle:[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/MedaPlayerUI.framework"]];
	});

	if (_notificationCell) {
		[_notificationCell removeFromSuperview];
		_notificationCell = nil;
	}

	NSArray *song = Songs[arc4random_uniform(Songs.count)];

	NCMutableNotificationRequest *request = [[%c(NCMutableNotificationRequest) alloc] init];
	request.sectionIdentifier = @"ws.hbang.canzone.app";

	NCMutableNotificationContent *content = [[%c(NCMutableNotificationContent) alloc] init];
	content.title = NSLocalizedStringFromTableInBundle(@"NOW_PLAYING_TITLE", @"Localizable", [NSBundle bundleForClass:self.class], nil);
	content.subtitle = song[0];
	content.message = song[1];
	content.date = [NSDate date];
	content.icon = CanzoneImage;
	content.attachmentImage = PlaceholderImage;
	request.content = [content copy];

	_notificationCell = [[%c(NCNotificationListCell) alloc] initWithFrame:CGRectInset(self.contentView.bounds, 15.f, 15.f)];
	_notificationCell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_notificationCell.contentViewController = [[%c(NCNotificationViewController) alloc] initWithNotificationRequest:[request copy]];
	_notificationCell.contentViewController.associatedView = _notificationCell;
	_notificationCell.insetMargins = UIEdgeInsetsMake(15.f, 15.f, 15.f, 15.f);
	_notificationCell.userInteractionEnabled = NO;
	_notificationCell.adjustsFontForContentSizeCategory = NO;
	_notificationCell.backgroundBlurred = YES;
	_notificationCell.configured = YES;
	[self.contentView addSubview:_notificationCell];
}

@end

