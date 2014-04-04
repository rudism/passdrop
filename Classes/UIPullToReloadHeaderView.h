//
//  UIPullToReloadHeaderView.h
//

/*
 
 Created by Water Lou | http://www.waterworld.com.hk
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>


typedef enum {
	kPullStatusReleaseToReload = 0,
	kPullStatusPullDownToReload	= 1,
	kPullStatusLoading = 2
} UIPullToReloadStatus;

#define kPullDownToReloadToggleHeight 65.0f

@interface UIPullToReloadHeaderView : UIView {	
@private
	UIPullToReloadStatus status;
	
	UILabel *lastUpdatedLabel;
	UILabel *statusLabel;
	UIImageView *arrowImage;
	UIActivityIndicatorView *activityView;
	
	NSDate *lastUpdatedDate;
	
	SystemSoundID popSound, pull1Sound, pull2Sound;
}

@property (nonatomic, retain) NSDate *lastUpdatedDate;
@property (nonatomic, readonly) UIPullToReloadStatus status;

- (void)setStatus:(UIPullToReloadStatus)status animated:(BOOL)animated;

- (void) startReloading:(UITableView *)tableView animated:(BOOL)animated;	// call when start loading
- (void) finishReloading:(UITableView *)tableView animated:(BOOL)animated;	// call when finish loading


@end
