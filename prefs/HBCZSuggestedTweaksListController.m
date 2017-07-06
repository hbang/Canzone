#import "HBCZSuggestedTweaksListController.h"
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIColor+Private.h>

@implementation HBCZSuggestedTweaksListController

#pragma mark - HBListController

+ (NSString *)hb_specifierPlist {
	return @"SuggestedTweaks";
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// if the tweak is paid, give it a blue tint color, otherwise use black. <3 apple for making the
	// system colors public in iOS 11
	PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.tintColor = cell.specifier.properties[@"isCommercial"] ? [UIColor systemDarkBlueColor] : [UIColor blackColor];
	return cell;
}

@end
