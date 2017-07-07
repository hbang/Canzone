#import "HBCZNotificationWidgetViewController.h"
#import "HBCZNowPlayingBulletinProvider.h"
#import "HBCZNowPlayingController.h"
#import "HBCZPreferences.h"
#import <MediaPlayerUI/MPUTransportControlsView.h>
#import <MediaPlayerUI/MPUNowPlayingArtworkView.h>
#import <UserNotificationsUIKit/NCNotificationViewController.h>
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

%hook NCNotificationListViewController

- (void)viewDidLoad {
	%orig;

	// register our custom reuse identifier
	[self.collectionView registerClass:%c(NCNotificationListCell) forCellWithReuseIdentifier:kHBCZNowPlayingCellIdentifier];
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

- (BOOL)_hb_isCanzoneNotification;
- (BOOL)_hb_isCanzoneLockNotification;

@property (nonatomic, retain) NSString *hb_canzoneSongIdentifier;
@property (nonatomic, retain) HBCZNotificationWidgetViewController *hb_canzoneWidgetViewController;
@property (nonatomic, retain) MPUTransportControlsView *hb_canzoneControlsView;

@end

%hook NCNotificationContentView

%property (nonatomic, retain) NSString *hb_canzoneSongIdentifier;
%property (nonatomic, retain) HBCZNotificationWidgetViewController *hb_canzoneWidgetViewController;

- (instancetype)initWithStyle:(NSInteger)style {
	self = %orig;

	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hb_canzoneThumbnailChanged:) name:HBCZNowPlayingArtworkChangedNotification object:nil];
	}

	return self;
}

%new - (BOOL)_hb_isCanzoneNotification {
	NCNotificationViewController *viewController = (NCNotificationViewController *)self._viewControllerForAncestor;

	if ([viewController isKindOfClass:%c(NCNotificationViewController)]) {
		NCNotificationRequest *request = viewController.notificationRequest;
		return request && request.hb_isCanzoneNotification;
	} else {
		return NO;
	}
}

%new - (BOOL)_hb_isCanzoneLockNotification {
	if (!self._hb_isCanzoneNotification) {
		return NO;
	}

	UIViewController *viewController = self._viewControllerForAncestor;

	// walk up the view controller hierarchy until we hit either SBDashBoardViewController, or nil.
	// we don't specifically use SBDashBoardMainPageViewController because metrolockscreen replaces
	// it, or something
	do {
		viewController = viewController.parentViewController;
	} while (viewController && ![viewController isKindOfClass:%c(SBDashBoardViewController)]);

	// if we got a non-nil view controller, we know we're on the lock screen
	return viewController != nil;
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

- (void)layoutSubviews {
	BOOL isCanzoneNotification = self._hb_isCanzoneNotification;

	if (isCanzoneNotification) {
		UIView *contentView = [self valueForKey:@"_contentView"];
		HBCZNotificationWidgetViewController *viewController = self.hb_canzoneWidgetViewController;

		if (preferences.showBannerControls && self._hb_isCanzoneLockNotification) {
			if (!viewController) {
				UIViewController *parentViewController = self._viewControllerForAncestor;

				viewController = [[%c(HBCZNotificationWidgetViewController) alloc] init];
				[viewController willMoveToParentViewController:parentViewController];
				viewController.view.frame = self.bounds;
				viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				[self addSubview:viewController.view];

				self.hb_canzoneWidgetViewController = viewController;
			}
		}

		viewController.view.hidden = !preferences.showBannerControls;
		contentView.hidden = !viewController.view.hidden;
	}

	%orig;
}

%end

#pragma mark - Constructor

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		preferences = [HBCZPreferences sharedInstance];

		%init;
	}
}
