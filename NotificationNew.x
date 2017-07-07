#import "HBCZNotificationListCell.h"
#import "HBCZNotificationWidgetViewController.h"
#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZNowPlayingController.h"
#import "HBCZPreferences.h"
#import <UserNotificationsUIKit/NCNotificationViewController.h>
#import <UserNotificationsUIKit/NCShortLookView.h>
#import <UIKit/UIView+Private.h>
#import <version.h>

#pragma mark - This should not be here lol

@interface NCNotificationContentView : UIView

@property (nonatomic, retain) UIImage *thumbnail;

@end

@interface NCNotificationRequest : NSObject // UNKit

@property (nonatomic, copy, readonly) NSString *sectionIdentifier;

@end

@interface NCNotificationExtensionContainerViewController : UIViewController

@property (nonatomic) BOOL userInteractionEnabled;

@end

@interface NCNotificationListViewController : UICollectionViewController

- (NCNotificationRequest *)notificationRequestAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface NCNotificationPriorityListViewController : NCNotificationListViewController

@end

#pragma mark - Variables

HBCZPreferences *preferences;

#pragma mark - Helpers

@interface NCNotificationRequest ()

- (BOOL)hb_isCanzoneNotification;

@end

%hook NCNotificationRequest

%new - (BOOL)hb_isCanzoneNotification {
	return [self.sectionIdentifier isEqualToString:kHBCZAppIdentifier];
}

%end

#pragma mark - Enable user interaction

%hook NCNotificationExtensionContainerViewController

- (instancetype)initWithExtension:(id)extension forNotificationRequest:(NCNotificationRequest *)request {
	self = %orig;

	if (self) {
		// if this is us, override and allow touches to be sent through to our remote view
		if (request.hb_isCanzoneNotification) {
			self.userInteractionEnabled = YES;
		}
	}

	return self;
}

%end

#pragma mark - Reuse identifier hax

static NSString *const kHBCZNowPlayingCellIdentifier = @"CanzoneNowPlayingCellIdentifier";

static BOOL reuseIdentifierHax = NO;

%hook NCNotificationPriorityListViewController

- (void)viewDidLoad {
	%orig;

	// register our custom reuse identifier
	[self.collectionView registerClass:%c(HBCZNotificationListCell) forCellWithReuseIdentifier:kHBCZNowPlayingCellIdentifier];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	// if this notification is one of ours (one of ours. one of ours.) then we apply the custom reuse
	// id. otherwise, nothing special will happen
	NCNotificationRequest *request = [self notificationRequestAtIndexPath:indexPath];

	reuseIdentifierHax = request.hb_isCanzoneNotification;
	UICollectionViewCell *cell = %orig;
	reuseIdentifierHax = NO;

	return cell;
}

%end

%hook NCNotificationListCollectionView

- (UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)reuseIdentifier forIndexPath:(NSIndexPath *)indexPath {
	return %orig(reuseIdentifierHax ? kHBCZNowPlayingCellIdentifier : reuseIdentifier, indexPath);
}

%end

#pragma mark - Content view stuff

@interface NCNotificationContentView ()

- (NCNotificationRequest *)_hb_canzoneNotificationRequest;
- (BOOL)_hb_isCanzoneNotification;
- (BOOL)_hb_isCanzoneLockNotification;

- (UIViewController *)_hb_canzoneWidgetViewController;

@property (nonatomic, retain) NSString *hb_canzoneSongIdentifier;
@property (nonatomic, retain) UIView *_hb_widgetView;

@end

%hook NCNotificationContentView

%property (nonatomic, retain) NSString *hb_canzoneSongIdentifier;
%property (nonatomic, retain) UIView *_hb_widgetView;

- (instancetype)initWithStyle:(NSInteger)style {
	self = %orig;

	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hb_canzoneThumbnailChanged:) name:HBCZNowPlayingArtworkChangedNotification object:nil];
	}

	return self;
}

%new - (NCNotificationRequest *)_hb_canzoneNotificationRequest {
	NCNotificationViewController *viewController = (NCNotificationViewController *)self._viewControllerForAncestor;
	return viewController && [viewController isKindOfClass:%c(NCNotificationViewController)] ? viewController.notificationRequest : nil;
}

%new - (BOOL)_hb_isCanzoneNotification {
	NCNotificationRequest *request = self._hb_canzoneNotificationRequest;
	return request && request.hb_isCanzoneNotification;
}

%new - (BOOL)_hb_isCanzoneLockNotification {
	if (!self._hb_isCanzoneNotification) {
		return NO;
	}

	// ugh. such a hack. sorry
	UIView *cell = self;

	do {
		cell = cell.superview;
	} while (cell != nil && ![cell isKindOfClass:%c(NCNotificationListCell)]);

	// kinda voids the point of this lol, but it'll do for now
	return !cell || cell.class == %c(HBCZNotificationListCell);
}

%new - (void)_hb_canzoneThumbnailChanged:(NSNotification *)notification {
	if (self._hb_isCanzoneNotification && !preferences.showBannerControls) {
		NSString *identifier = self.hb_canzoneSongIdentifier;

		if (!identifier) {
			// TODO: this is probably stupidly naive? lol
			identifier = notification.userInfo[@"identifier"];
			self.hb_canzoneSongIdentifier = identifier;
		}

		if ([identifier isEqualToString:notification.userInfo[@"identifier"]]) {
			self.thumbnail = [UIImage imageWithData:notification.userInfo[@"artwork"]];
		}
	}
}

- (BOOL)_shouldReverseLayoutDirection {
	return self._hb_isCanzoneNotification ? YES : %orig;
}

- (CGRect)_frameForThumbnailInRect:(CGRect)rect {
	CGRect newFrame = %orig;

	if (self._hb_isCanzoneNotification) {
		newFrame.origin.y -= 4.f;
		newFrame.size.width += 4.f;
		newFrame.size.height += 4.f;
	}

	return newFrame;
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize newSize = %orig;

	// if we've got the widget, force the right size
	NSLog(@"[[CZ]] has widget? %@",self._hb_widgetView);
	if (self._hb_widgetView || (self._hb_isCanzoneLockNotification && preferences.showBannerControls)) {
		newSize.height = 95;
	}

	return newSize;
}

%new - (UIView *)hb_widgetView {
	return self._hb_widgetView;
}

%new - (void)hb_setWidgetView:(UIView *)view {
	if (view) {
		[self addSubview:view];
		self._hb_widgetView = view;
	} else {
		[self._hb_widgetView removeFromSuperview];
		self._hb_widgetView = nil;
	}

	// hide the content view if we have the widget
	UIView *contentView = [self valueForKey:@"_contentView"];
	contentView.hidden = view != nil;

	[self setNeedsLayout];
}

%end

#pragma mark - Constructor

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		preferences = [HBCZPreferences sharedInstance];

		%init;
	}
}
