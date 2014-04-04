//
//  RootViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DatabaseManager.h"
#import <DropboxSDK/DropboxSDK.h>
#import "DropBoxBrowserController.h"
#import "SettingsViewController.h"
#import "EditDatabaseViewController.h"
#import "KdbGroupViewController.h"
#import "KdbReader.h"
#import "KdbGroup.h"
#import "NetworkActivityViewController.h"
#import "SettingsViewController.h"

@interface RootViewController : NetworkActivityViewController<DatabaseManagerDelegate, DatabaseDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
	SettingsViewController *settingsView;
	DatabaseManager *dbManager;
	DropBoxBrowserController *dbRootView;
	int extraRows;
	id<Database> loadingDb;
    int alertMode;
    id<Database> unlocking;
    BOOL tutorialShown;
}

@property (nonatomic, retain) SettingsViewController *settingsView;
@property (nonatomic, retain) DatabaseManager *dbManager;
@property (nonatomic, retain) DropBoxBrowserController *dbRootView;
@property (nonatomic) int extraRows;
@property (nonatomic, retain) id<Database> loadingDb;

- (void) settingsButtonClicked;
- (void) dropboxWasReset;
//- (void) dismissHelp;
//- (void) closeHelp;
- (void) gotoDropBox;
- (UITableView*) tableView;
- (void) completeLoad;
- (void) removeLock:(id<Database>)database;

@end
