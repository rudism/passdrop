//
//  DropBoxBrowserController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "LoadingView.h"
#import "UIPullToReloadTableViewController.h"
#import "PassDropAppDelegate.h"
#import "NewDatabaseViewController.h"


@interface DropBoxBrowserController : UIPullToReloadTableViewController<DBRestClientDelegate, NewDatabaseDelegate> {
	DBRestClient *restClient;
	NSString *myPath;
	BOOL isLoaded;
	LoadingView *loadingView;
	NSString *metadataHash;
	NSArray *dirContents;
	NSMutableDictionary *dirBrowsers;
	NSString *tempDbId;
	NSString *tempPath;
	DatabaseManager *dbManager;
}

@property (retain, nonatomic) DBRestClient *restClient;
@property (retain, nonatomic) NSString *myPath;
@property (nonatomic) BOOL isLoaded;
@property (retain, nonatomic) LoadingView *loadingView;
@property (retain, nonatomic) NSString *metadataHash;
@property (retain, nonatomic) NSArray *dirContents;
@property (retain, nonatomic) NSMutableDictionary *dirBrowsers;
@property (retain, nonatomic) NSString *tempDbId;
@property (retain, nonatomic) NSString *tempPath;
@property (retain, nonatomic) DatabaseManager *dbManager;

- (id) initWithPath:(NSString*)path;
- (void)refreshDirectory;
- (void)setWorking:(BOOL)working;
- (void)networkRequestStarted;
- (void)networkRequestStopped;
- (void)alertError:(NSError*)error;
- (void)alertMessage:(NSString*)message withTitle:(NSString*)alertTitle;
- (void)reset;

@end
