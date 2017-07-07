#import "HBCZNotificationWidgetViewController.h"
#import <version.h>

%subclass HBCZNotificationWidgetViewController : UIViewController

- (void)loadView {
	%orig;

	WGWidgetDiscoveryController *discoverer = [[%c(WGWidgetDiscoveryController) alloc] initWithColumnModes:0];
	[discoverer beginDiscovery];

	WGWidgetHostingViewController *viewController = [discoverer widgetWithIdentifier:@"ws.hbang.canzone.app.nowplayingwidget" delegate:self forRequesterWithIdentifier:@"ws.hbang.canzone.app"];

	[viewController willMoveToParentViewController:self];
	viewController.view.frame = self.view.bounds;
	viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:viewController.view];
}

#pragma mark - Widget hosting

%new - (CGSize)maxSizeForWidget:(WGWidgetHostingViewController *)widgetViewController forDisplayMode:(NCWidgetDisplayMode)displayMode {
	return CGSizeMake(self.view.frame.size.width, 65);
}

%new - (NCWidgetDisplayMode)activeLayoutModeForWidget:(WGWidgetHostingViewController *)widgetViewController {
	return NCWidgetDisplayModeCompact;
}

%new - (UIEdgeInsets)marginInsetsForWidget:(WGWidgetHostingViewController *)widgetViewController {
	return UIEdgeInsetsZero;
}

%end

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		%init;
	}
}
