//
//  SettingsView.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "PassDropAppDelegate.h"
#import "AboutViewController.h"


@interface SettingsViewController : UIViewController<UITableViewDelegate, UIActionSheetDelegate> {
	IBOutlet UITableView *settingsTable;
	UISwitch *autoClearSwitch;
    UISwitch *ignoreBackupSwitch;
	UIViewController *aboutView;
}

@property (retain, nonatomic) IBOutlet UITableView *settingsTable;
@property (retain, nonatomic) UISwitch *autoClearSwitch;
@property (retain, nonatomic) UISwitch *ignoreBackupSwitch;
@property (retain, nonatomic) UIViewController *aboutView;

- (IBAction)dbButtonClicked;
- (void) openLastSwitched;
- (void)updateSettingsUI;
- (NSString*)convertSecondsToString:(int)seconds;
- (int)convertArrayTimesIndexToSeconds:(int)index;
- (NSString*)openModeStringForMode:(int)openMode;

@end
