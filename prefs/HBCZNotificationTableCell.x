#import "HBCZNotificationTableCell.h"
#import <Preferences/PSSpecifier.h>
#include <dlfcn.h>

@interface NCNotificationRequest : NSObject

+ (instancetype)notificationRequestWithSectionId:(NSString *)sectionID notificationId:(NSString *)notificationID threadId:(NSString *)threadID title:(NSString *)title message:(NSString *)message timestamp:(NSDate *)timestamp destinations:(NSSet *)destinations;

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
		wallpaperView.image = [UIImage imageWithContentsOfFile:@"~/Library/SpringBoard/LockBackgroundThumbnail.jpg".stringByExpandingTildeInPath];
		wallpaperView.contentMode = UIViewContentModeScaleAspectFill;
		wallpaperView.clipsToBounds = YES;
		[self.contentView addSubview:wallpaperView];

		[self _setUpNotification];
	}

	return self;
}

- (void)_setUpNotification {
	dlopen("/Library/MobileSubstrate/DynamicLibraries/Canzone.dylib", RTLD_LAZY);

	if (_notificationCell) {
		[_notificationCell removeFromSuperview];
		_notificationCell = nil;
	}

	[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/UserNotificationsUIKit.framework"] load];

	NCNotificationRequest *request = [%c(NCNotificationRequest) notificationRequestWithSectionId:@"ws.hbang.canzone.app" notificationId:@"0" threadId:@"0" title:@"Now Playing" message:@"Take on Me\nHunting High and Low\na-ha" timestamp:[NSDate date] destinations:[NSSet set]];

	_notificationCell = [[%c(NCNotificationListCell) alloc] initWithFrame:CGRectInset(self.contentView.bounds, 15.f, 15.f)];
	_notificationCell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_notificationCell.contentViewController = [[%c(NCNotificationViewController) alloc] initWithNotificationRequest:request];
	_notificationCell.contentViewController.associatedView = _notificationCell;
	_notificationCell.insetMargins = UIEdgeInsetsMake(15.f, 15.f, 15.f, 15.f);
	_notificationCell.userInteractionEnabled = NO;
	_notificationCell.adjustsFontForContentSizeCategory = YES;
	_notificationCell.backgroundBlurred = YES;
	_notificationCell.configured = YES;
	[self.contentView addSubview:_notificationCell];
}

@end

