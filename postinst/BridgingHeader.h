@import Foundation;
@import MobileCoreServices;

//#import <Foundation/NSExtension.h>

typedef void (^NSExtensionMatchingCompletion)(NSArray *result);

@interface PKDiscoveryDriver : NSObject @end

@class PKDiscoveryDriver;

@interface NSExtension : NSObject

+ (PKDiscoveryDriver *)beginMatchingExtensionsWithAttributes:(NSDictionary *)attributes completion:(NSExtensionMatchingCompletion)completion;
+ (void)endMatchingExtensions:(PKDiscoveryDriver *)discoverer;

@property (nonatomic, retain) NSString *identifier;

@end

#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSPlugInKitProxy.h>
