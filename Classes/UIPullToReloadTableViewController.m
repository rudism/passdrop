//
//  UIPullToReloadTableViewController.m
//  pullToReloadTableViewTest

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

#import "UIPullToReloadTableViewController.h"

@implementation UIPullToReloadTableViewController

@synthesize pullToReloadHeaderView;

- (void) viewDidLoad {
    [super viewDidLoad];
	
	pullToReloadHeaderView = [[UIPullToReloadHeaderView alloc] initWithFrame: CGRectMake(0.0f, 0.0f - self.view.bounds.size.height,
																						 self.view.bounds.size.width, self.view.bounds.size.height)];
	[self.tableView addSubview:pullToReloadHeaderView];
}

-(void) viewDidUnload {
	[super viewDidUnload];
	[pullToReloadHeaderView release]; pullToReloadHeaderView = nil;	
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if ([pullToReloadHeaderView status] == kPullStatusLoading) return;
	checkForRefresh = YES;  //  only check offset when dragging
} 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([pullToReloadHeaderView status] == kPullStatusLoading) return;
	
	if (checkForRefresh) {
		if (scrollView.contentOffset.y > -kPullDownToReloadToggleHeight && scrollView.contentOffset.y < 0.0f) {
			[pullToReloadHeaderView setStatus:kPullStatusPullDownToReload animated:YES];
			
		} else if (scrollView.contentOffset.y < -kPullDownToReloadToggleHeight) {
			[pullToReloadHeaderView setStatus:kPullStatusReleaseToReload animated:YES];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ([pullToReloadHeaderView status] == kPullStatusLoading) return;
	
	if ([pullToReloadHeaderView status]==kPullStatusReleaseToReload) {
		[pullToReloadHeaderView startReloading:self.tableView animated:YES];
		[self pullDownToReloadAction];
	}
	checkForRefresh = NO;
}

#pragma mark actions

-(void) pullDownToReloadAction {
	NSLog(@"TODO: Overload this");
}


@end

