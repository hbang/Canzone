#import "HBCZMusicProvider.h"

@implementation HBCZMusicProvider {
	NSString *_lastSongIdentifier;
}

- (instancetype)init {
	self = [super init];
	
	if (self) {
		self.name = @"Canzone";
		self.preferencesBundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/Canzone.bundle"];
		self.preferencesClass = @"HBCZRootListController";
	}
	
	return self;
}

@end
