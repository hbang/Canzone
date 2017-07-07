#import <UserNotificationsUIKit/NCNotificationViewController.h>

@interface NCNotificationListCell : UICollectionViewCell

@property (nonatomic, retain) NCNotificationViewController *contentViewController;

@end

@class HBCZNotificationWidgetViewController;

@interface HBCZNotificationListCell : NCNotificationListCell

- (BOOL)_hb_isCanzoneNotification;
- (BOOL)_hb_isCanzoneLockNotificationForViewController:(UIViewController *)viewController;

@property (nonatomic, retain) HBCZNotificationWidgetViewController *hb_canzoneWidgetViewController;

@end
