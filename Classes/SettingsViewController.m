//
//  SettingsView.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "Global.h"
#import <DropboxSDK/DropboxSDK.h>


@implementation SettingsViewController

@synthesize settingsTable;
@synthesize autoClearSwitch;
@synthesize ignoreBackupSwitch;
@synthesize aboutView;

int pickerViewMode;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

#pragma mark -
#pragma mark view lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    
	autoClearSwitch = [[UISwitch alloc] init];
    ignoreBackupSwitch = [[UISwitch alloc] init];
    
    [autoClearSwitch setOn:app.prefs.autoClearClipboard animated:NO];
    [autoClearSwitch addTarget:self action:@selector(openLastSwitched) forControlEvents:UIControlEventValueChanged];
    
    [ignoreBackupSwitch setOn:app.prefs.ignoreBackup animated:NO];
    [ignoreBackupSwitch addTarget:self action:@selector(ignoreBackupSwitched) forControlEvents:UIControlEventValueChanged];
    
	aboutView = [[AboutViewController alloc] init];
	aboutView.title = @"About";
	
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    app.settingsView = self;
	[super viewDidAppear:animated];
	[self updateSettingsUI];
}

- (void) viewWillDisappear:(BOOL)animated {
    PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    app.settingsView = nil;
}

#pragma mark -
#pragma mark ui actions

- (IBAction)dbButtonClicked {
	if([[DBSession sharedSession] isLinked]){
		UIAlertView *unlinkConfirm = [[UIAlertView alloc] initWithTitle:@"Unlink DropBox" message:@"Are you sure you want to unlink your DropBox account? This will also remove all databases from your device." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlink",nil];
		[unlinkConfirm show];
		[unlinkConfirm release];
	} else {
		//DBLoginController *dbLoginController = [[DBLoginController new] autorelease];
		//[dbLoginController presentFromController:self];
        [[DBSession sharedSession] linkFromController:self];
	}
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)index {
	if(index == 1){
		PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
		[[DBSession sharedSession] unlinkAll];
		[app dropboxWasReset];
		[self updateSettingsUI];
	}
}

- (void)updateSettingsUI {
	[settingsTable reloadData];
}

- (void) openLastSwitched {
	PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
	app.prefs.autoClearClipboard = autoClearSwitch.on;
	[app.prefs savePrefs];
}

- (void) ignoreBackupSwitched {
	PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
	app.prefs.ignoreBackup = ignoreBackupSwitch.on;
	[app.prefs savePrefs];
}

#pragma mark -
#pragma mark dropbox delegate

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate{
    return YES;
}

#pragma mark -
#pragma mark table delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 3;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"Database Sources";
			break;
		case 1:
			return @"PassDrop Settings";
			break;
		case 2:
			return nil;
			break;
		default:
			break;
	}
	return nil;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return 1;
			break;
		case 1:
			return 4;
			break;
		case 2:
			return 1;
			break;
		default:
			break;
	}
	return 0;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    UIActionSheet *actionSheet;
	switch ([indexPath section]) {
		case 0:
			[self dbButtonClicked];
			break;
		case 1:
			switch ([indexPath row]) {
				case 2:
					// clear clipboard
					break;
				case 0:
					// lock in background
                    pickerViewMode = 1;
                    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Immediately", @"10 secs", @"30 secs", @"1 min", @"5 mins", @"10 mins", @"30 mins", @"1 hour", @"2 hours", @"Never", nil];
                    //[actionSheet showInView:self.view];
                    [actionSheet showFromRect:[tableView cellForRowAtIndexPath:indexPath].frame inView:self.view animated:YES];
                    [actionSheet release];
					break;
				case 1:
                    pickerViewMode = 2;
                    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Writable", @"Read Only", @"Always Ask", nil];
                    //[actionSheet showInView:self.view];
                    [actionSheet showFromRect:[tableView cellForRowAtIndexPath:indexPath].frame inView:self.view animated:YES];
                    [actionSheet release];
					break;
                case 4:
                    // ignore backups
                    break;
				default:
					break;
			}
			break;
		case 2:
			// show about screen
			[[self navigationController] pushViewController:aboutView animated:YES];
			break;
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark table data source

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *cellIdentifier = @"Cell";
    static NSString *switchCellIdentifier = @"SwitchCell";
    static NSString *valueCellIdentifier = @"ValueCell";
    
    UITableViewCell *cell;
    PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if(indexPath.section == 0 || (indexPath.section == 1 && indexPath.row < 2)){
        cell = [tableView dequeueReusableCellWithIdentifier:valueCellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:valueCellIdentifier] autorelease];
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
        if(indexPath.section == 0){
            cell.textLabel.text = @"DropBox";
            if([[DBSession sharedSession] isLinked]){
                cell.detailTextLabel.text = @"Linked";
            } else {
                cell.detailTextLabel.text = @"Not Linked";
            }
        } else {
            switch ([indexPath row]) {
				case 0:
					cell.textLabel.text = @"Lock In Background";
					cell.detailTextLabel.text = [self convertSecondsToString:app.prefs.lockInBackgroundSeconds];
					break;
				case 1:
					cell.textLabel.text = @"Open Databases";
					cell.detailTextLabel.text = [self openModeStringForMode:app.prefs.databaseOpenMode];
					break;
			}
        }
    } else if(indexPath.section == 1 && (indexPath.row == 2 || indexPath.row == 3)){
        cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellIdentifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if(indexPath.row == 2){
            cell.textLabel.text = @"Auto-Clear Clipboard";
            cell.accessoryView = autoClearSwitch;
        } else {
            cell.textLabel.text = @"Search Ignores Backup";
            cell.accessoryView = ignoreBackupSwitch;
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        }
        cell.textLabel.text = @"About PassDrop";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	return cell;
}

#pragma mark -
#pragma mark pref data conversion helpers

- (NSString*)openModeStringForMode:(int)openMode {
	switch (openMode) {
		case kOpenModeWritable:
			return @"Writable";
			break;
		case kOpenModeReadOnly:
			return @"Read Only";
			break;
		case kOpenModeAlwaysAsk:
			return @"Always Ask";
			break;
	}
	return nil;
}

- (int)convertArrayTimesIndexToSeconds:(int)index {
	switch(index){
		case 0:
			return 0;
			break;
		case 1:
			return 10;
			break;
		case 2:
			return 30;
			break;
		case 3:
			return 60;
			break;
		case 4:
			return 300;
			break;
		case 5:
			return 600;
			break;
		case 6:
			return 1800;
			break;
		case 7:
			return 3600;
			break;
		case 8:
			return 7200;
			break;
	}
	return -1;
}

- (NSString*)convertSecondsToString:(int)seconds {
    switch(seconds){
        case -1:
            return @"Never";
            break;
		case 0:
			return @"Immediately";
			break;
		case 10:
			return @"10 secs";
			break;
		case 30:
			return @"30 secs";
			break;
		case 60:
			return @"1 min";
			break;
		case 300:
			return @"5 mins";
			break;
		case 600:
			return @"10 mins";
			break;
		case 1800:
			return @"30 mins";
			break;
		case 3600:
			return @"1 hour";
			break;
		case 7200:
			return @"2 hours";
			break;
	}
    return [NSString stringWithFormat:@"%d secs", seconds];
}

#pragma mark -
#pragma mark picker view stuff

 - (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
     PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
     if(pickerViewMode == 1 && buttonIndex < 10){
         app.prefs.lockInBackgroundSeconds = [self convertArrayTimesIndexToSeconds:buttonIndex];
     } else {
         if(buttonIndex < 3){
             app.prefs.databaseOpenMode = buttonIndex;
         }
     }
     [app.prefs savePrefs];
     [self updateSettingsUI];
 }


#pragma mark -
#pragma mark memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[aboutView release];
	[autoClearSwitch release];
	[settingsTable release];
    [super dealloc];
}


@end
