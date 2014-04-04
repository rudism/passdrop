//
//  PassDropAppDelegate.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "AppPrefs.h"
#import "DatabaseManager.h"
#import "MGSplitViewController.h"
#import "HideViewController.h"

@class SettingsViewController;
@class RootViewController;

@interface PassDropAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
    MGSplitViewController *splitController;
	
	DBSession *dbSession;
	AppPrefs *prefs;
	DatabaseManager *dbManager;
    
    NSDate *bgTimer;
    BOOL isLocked;
    
    HideViewController *hide;
    RootViewController *rootView;
    
    SettingsViewController *settingsView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet MGSplitViewController *splitController;
@property (nonatomic, retain) IBOutlet RootViewController *rootView;
@property (nonatomic, retain) DBSession *dbSession;
@property (retain, nonatomic) AppPrefs *prefs;
@property (retain, nonatomic) DatabaseManager *dbManager;
@property (retain, nonatomic) SettingsViewController *settingsView;

- (void) dropboxWasReset;

@end

