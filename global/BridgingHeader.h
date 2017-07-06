@import UIKit;
#import <Cephei/UIView+CompactConstraint.h>
#import <MediaPlayerUI/MPUControlCenterMediaControlsView.h>
#import <MediaPlayerUI/MPUControlCenterMediaControlsViewController.h>
#import <MediaPlayerUI/MPUControlCenterMetadataView.h>
#import <MediaPlayerUI/MPUNowPlayingArtworkView.h>
#import <MediaPlayerUI/MPUNowPlayingController.h>
#import <MediaPlayerUI/MPUNowPlayingMetadata.h>
#import <MediaPlayerUI/MPUTransportControlsView.h>
#import <MediaRemote/MediaRemote.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <UIKit/UIColor+Private.h>

typedef NS_ENUM(NSInteger, MPUNowPlayingTitlesViewStyle) {
	MPUNowPlayingTitlesViewStyleIdk
};

@interface MPUNowPlayingTitlesView : UIView

- (instancetype)initWithStyle:(MPUNowPlayingTitlesViewStyle)style;

@property (nonatomic) MPUNowPlayingTitlesViewStyle style;

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *albumText;
@property (nonatomic, copy) NSString *artistText;
@property (nonatomic, copy) NSString *stationNameText;

@property (nonatomic, retain) NSDictionary *titleTextAttributes;
@property (nonatomic, retain) NSDictionary *detailTextAttributes;

@property (getter=isExplicit, nonatomic) BOOL explicit;

@property (getter=isMarqueeEnabled, nonatomic) BOOL marqueeEnabled;

@end
