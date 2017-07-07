@import NotificationCenter;

@class WGWidgetHostingViewController;

@protocol WGWidgetHostingViewControllerDelegate <NSObject>

@required

- (CGSize)maxSizeForWidget:(WGWidgetHostingViewController *)widgetViewController forDisplayMode:(NCWidgetDisplayMode)displayMode;

@optional

- (void)remoteViewControllerDidConnectForWidget:(WGWidgetHostingViewController *)widgetViewController;
- (void)remoteViewControllerDidDisconnectForWidget:(WGWidgetHostingViewController *)widgetViewController;
- (void)remoteViewControllerViewDidAppearForWidget:(WGWidgetHostingViewController *)widgetViewController;
- (void)remoteViewControllerViewDidHideForWidget:(WGWidgetHostingViewController *)widgetViewController;
- (void)brokenViewDidAppearForWidget:(WGWidgetHostingViewController *)widgetViewController;
- (void)contentAvailabilityDidChangeForWidget:(WGWidgetHostingViewController *)widgetViewController;

- (NCWidgetDisplayMode)activeLayoutModeForWidget:(WGWidgetHostingViewController *)widgetViewController;
- (UIEdgeInsets)marginInsetsForWidget:(WGWidgetHostingViewController *)widgetViewController;

- (void)widget:(WGWidgetHostingViewController *)widgetViewController didChangeLargestSupportedDisplayMode:(NCWidgetDisplayMode)largestDisplayMode;
- (id)widget:(WGWidgetHostingViewController *)widgetViewController didUpdatePreferredHeight:(CGFloat)preferredHeight completion:(id)completion;

- (BOOL)shouldRequestWidgetRemoteViewControllers;

@end

@interface WGWidgetHostingViewController : UIViewController

@end

@class WGWidgetDiscoveryController;

@protocol WGWidgetDiscoveryControllerDelegate <NSObject>

@optional

- (BOOL)widgetDiscoveryControllerShouldIncludeInternalWidgets:(WGWidgetDiscoveryController *)discoveryController;

- (BOOL)widgetDiscoveryController:(WGWidgetDiscoveryController *)discoveryController shouldPurgeArchivedSnapshotsForWidgetWithBundleIdentifier:(NSString *)bundleIdentifier;
- (void)widgetDiscoveryController:(WGWidgetDiscoveryController *)discoveryController widgetWithBundleIdentifier:(NSString *)bundleIdentifier didEncounterProblematicSnapshotAtURL:(NSURL *)snapshotURL;

- (UIViewController *)widgetDiscoveryController:(WGWidgetDiscoveryController *)discoveryController preferredViewControllerForPresentingFromViewController:(UIViewController *)viewController;
- (void)widgetDiscoveryController:(WGWidgetDiscoveryController *)discoveryController requestUnlockWithCompletion:(id)completion;

- (id)whiteStatusBarAssertionForWidgetDiscoveryController:(WGWidgetDiscoveryController *)discoveryController;
- (void)widgetDiscoveryController:(WGWidgetDiscoveryController *)discoveryController didEndUsingStatusBarAssertion:(id)statusBarAssertion;

@end

@interface WGWidgetDiscoveryController : NSObject

- (instancetype)initWithColumnModes:(NSUInteger)columnModes;

@property (nonatomic, weak) id <WGWidgetDiscoveryControllerDelegate> delegate;

- (void)beginDiscovery;

- (WGWidgetHostingViewController *)widgetWithIdentifier:(NSString *)identifier delegate:(id<WGWidgetHostingViewControllerDelegate>)delegate forRequesterWithIdentifier:(NSString *)requesterIdentifier;

@end

////////

@interface HBCZNotificationWidgetViewController : UIViewController <WGWidgetDiscoveryControllerDelegate, WGWidgetHostingViewControllerDelegate>

@end
