#import "HBCZRootListController.h"
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSystemPolicyForApp.h>
#import <Preferences/PSTableCell.h>

@implementation HBCZRootListController

#pragma mark - Constants

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

+ (NSString *)hb_shareText {
	NSBundle *bundle = [NSBundle bundleForClass:self.class];
	return [NSString stringWithFormat:[bundle localizedStringForKey:@"SHARE_TEXT" value:nil table:@"Root"], [UIDevice currentDevice].localizedModel];
}

+ (NSURL *)hb_shareURL {
	return [NSURL URLWithString:@"https://cydia.hbang.ws/package/ws.hbang.canzone/"];
}

#pragma mark - UIViewController

- (instancetype)init {
	self = [super init];

	if (self) {
		HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
		appearanceSettings.tintColor = [UIColor colorWithRed:255.f / 255.f green:45.f / 255.f blue:85.f / 255.f alpha:1];
		self.hb_appearanceSettings = appearanceSettings;
	}

	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self _setUpSpecifiers];
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];
	[self _setUpSpecifiers];
}

- (void)_setUpSpecifiers {
	// grab the typestatus plus bundle
	NSBundle *plusBundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/TypeStatusPlus.bundle"];
	PSSpecifier *notificationSpecifier;
	BOOL providerEnabled = NO;

	// remove specifiers based on whether it’s installed or not
	if (plusBundle.executableURL) {
		[self removeSpecifierID:@"NotificationsGroup"];
		[self removeSpecifierID:@"TypeStatusPlusNotInstalledGroup"];
		[self removeSpecifierID:@"TypeStatusPlusNotInstalled"];
		notificationSpecifier = [self specifierForID:@"TypeStatusPlusNotificationsGroup"];
		providerEnabled = ((NSNumber *)[self readPreferenceValue:[self specifierForID:@"TypeStatusPlus"]]).boolValue;
	} else {
		[self removeSpecifierID:@"TypeStatusPlusNotificationsGroup"];
		[self removeSpecifierID:@"TypeStatusPlusGroup"];
		[self removeSpecifierID:@"TypeStatusPlus"];
		notificationSpecifier = [self specifierForID:@"NotificationsGroup"];
	}

	// if we don’t already have a notifications cell
	if (![self specifierForID:@"NOTIFICATIONS"]) {
		// construct a system notification settings cell
		PSSystemPolicyForApp *policy = [[PSSystemPolicyForApp alloc] initWithBundleIdentifier:@"ws.hbang.canzone.app"];

		// this usually returns an array of specifiers, including the “allow [app] to access” group
		// specifier, which we kinda don’t want. after this method does its thing, notificationSpecifier
		// will be non-nil, and we can just add that
		[policy specifiersForPolicyOptions:PSSystemPolicyOptionsNotifications force:YES];
		
		[self insertSpecifier:policy.notificationSpecifier afterSpecifier:notificationSpecifier];
	}

	BOOL doDisable = NO;

	// this kinda silly for loop will disable the notification cells when the provider is enabled
	for (PSSpecifier *specifier in _specifiers) {
		// if we’re at the start of the notifications group, we know to start on the next specifier. if
		// we’re at the start of the about group, we can stop on this specifier. otherwise, if we’re
		// in the notification cells area, set the cells and specifiers’ enabled state accordingly
		if (specifier == notificationSpecifier) {
			doDisable = YES;
		} else if ([specifier.identifier isEqualToString:@"AboutGroup"]) {
			doDisable = NO;
		} else if (doDisable) {
			specifier.properties[PSEnabledKey] = @(!providerEnabled);
			PSTableCell *cell = [self cachedCellForSpecifier:specifier];
			cell.cellEnabled = !providerEnabled;
		}
	}
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];

	// if the typestatus plus specifier has been toggled, update the enabled/disabled state of the
	// notification specifiers
	if ([specifier.identifier isEqualToString:@"TypeStatusPlus"]) {
		[self _setUpSpecifiers];
	}
}

@end
