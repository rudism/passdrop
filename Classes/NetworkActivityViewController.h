//
//  NetworkActivityViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "LoadingView.h"

@interface NetworkActivityViewController : UIViewController {
	LoadingView *loadingView;
	NSString *loadingMessage;
}

@property (retain, nonatomic) LoadingView *loadingView;
@property (retain, nonatomic) NSString *loadingMessage;

- (void)setWorking:(BOOL)working;
- (void)networkRequestStarted;
- (void)networkRequestStopped;

@end
