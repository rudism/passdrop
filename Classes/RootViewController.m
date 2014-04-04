//
//  RootViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController

@synthesize settingsView;
@synthesize dbManager;
@synthesize dbRootView;
@synthesize extraRows;
@synthesize loadingDb;

#pragma mark -
#pragma mark View lifecycle


- (void) viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.title = @"Databases";
	
	PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
	dbManager = app.dbManager;
	dbManager.delegate = self;

	settingsView = [[SettingsViewController alloc] init];
	settingsView.title = @"Settings";
    
    UIBarButtonItem *settingsButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonClicked)] autorelease];
	self.navigationItem.leftBarButtonItem = settingsButtonItem;
	
	extraRows = 0;
    tutorialShown = NO;
}

// hack to fix weird bug with the leftbarbuttonitems disappearing
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        UIBarButtonItem *sb = self.navigationItem.leftBarButtonItem;
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:sb.title style:sb.style target:sb.target action:sb.action] autorelease];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem.enabled = [[DBSession sharedSession] isLinked];
	[[self.view viewWithTag:1] setHidden:[[DBSession sharedSession] isLinked]];
	
	// hack to fix issue with disappearing insert/delete control icons
	if(self.tableView.editing){
		[self.tableView setEditing:NO animated:NO];
		[self.tableView setEditing:YES animated:NO];
	} else {
		[self.tableView reloadData]; // in case titles changed on the edit screen
	}
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    
	if(app.prefs.firstLoad && tutorialShown == NO){
        [app.prefs savePrefs]; // sets version
        tutorialShown = YES;
		if([dbManager.databases count] == 0){
            if(![[DBSession sharedSession] isLinked]){
                alertMode = 1;
                UIAlertView *helpView = [[UIAlertView alloc] initWithTitle:@"Tutorial" message:@"Welcome to PassDrop! Since this is your first time using PassDrop, you will need enter your DropBox credentials on the settings screen." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
                [helpView show];
                [helpView release];
            } else {
                alertMode = 2;
                UIAlertView *helpView = [[UIAlertView alloc] initWithTitle:@"Tutorial" message:@"Now that you have linked your DropBox account, you need to create or choose a KeePass 1.x database to use with PassDrop." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"DropBox", nil];
                [helpView show];
                [helpView release];
			}
		}
	}
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    if(self.tableView.isEditing){
        [self setEditing:NO animated:NO];
    }
	[super viewDidDisappear:animated];
}


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
#pragma mark Subview Handling

/*- (void) overlayWillOpen {
}

- (void) overlayDidOpen {
}

- (void) overlayDidClose {
	helpView.view.hidden = YES;
	[self.view bringSubviewToFront:helpView.view];
	[helpView.view removeFromSuperview];
	[helpView release];
	helpView = nil;
	self.tableView.userInteractionEnabled = YES;
}

- (void)dismissHelp {
	[self closeHelp];
	PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
	app.prefs.firstLoad = NO;
	[app.prefs savePrefs];
}

- (void)closeHelp {
	if(helpView != nil && [helpView isOpen]){
		[helpView closeToFrame:CGRectMake(0.0f, 420.0f, 320.0f, 230.0f)];
	}
}*/

- (UITableView*)tableView {
	return (UITableView*)[self.view viewWithTag:10];
}

#pragma mark -
#pragma mark Actions

- (void) settingsButtonClicked {
	[[self navigationController] pushViewController:settingsView animated:YES];
}

- (void)gotoDropBox {
	if(![[DBSession sharedSession] isLinked]){
        alertMode = 1;
		UIAlertView *notLinked = [[UIAlertView alloc] initWithTitle:@"DropBox Not Linked" message:@"Before you can add databases, you must link your DropBox account from the settings screen. Do you want to do that now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings",nil];
		[notLinked show];
		[notLinked release];
	} else {
		if(dbRootView == nil){
			dbRootView = [[DropBoxBrowserController alloc] initWithPath:@"/"];
			dbRootView.dbManager = dbManager;
			dbRootView.title = @"DropBox";
		}
		[[self navigationController] pushViewController:dbRootView animated:YES];
	}
}

- (void)databaseWasAdded:(NSString *)databaseName {
    PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
	app.prefs.firstLoad = NO;
	[app.prefs savePrefs];
    
	while([[self.navigationController viewControllers] count] > 1){
		[self.navigationController popViewControllerAnimated:NO];
	}
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[dbManager.databases count]-1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)dropboxWasReset {
	[self.tableView reloadData];
	[dbRootView reset];
}

- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if(alertMode == 1 && buttonIndex == 1){
		// means they clicked the settings button
		[self settingsButtonClicked];
        tutorialShown = NO;
	} else if(alertMode == 2 && buttonIndex == 1){
        // clicked the dropbox button
        [self gotoDropBox];
        tutorialShown = NO;
    } else if(alertMode == 3 && buttonIndex == 1){
        if([[alertView textFieldAtIndex:0].text length] > 0){
            if([unlocking loadWithPassword:[alertView textFieldAtIndex:0].text]){
                [self userUnlockedDatabase:unlocking];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[unlocking lastError] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must enter your password." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    } else if(alertMode == 4){
        [self databaseUpdateComplete:unlocking];
    } else if(buttonIndex == 0){
        PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
        app.prefs.firstLoad = NO;
        [app.prefs savePrefs];
    }
}

- (void)removeLock:(id<Database>)database {
    if(!database.isReadOnly){
        self.loadingMessage = @"Unlocking";
        [self networkRequestStarted];
        database.delegate = self;
        [database removeLock];
    }
}


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [dbManager.databases count] + extraRows;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	if(tableView.editing && [indexPath row] == [dbManager.databases count]){
		[[cell imageView] setImage:nil];
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.text = @"Add Database";
	} else if ([indexPath row] < [dbManager.databases count]) {
		[[cell imageView] setImage:[UIImage imageNamed:@"keepass_icon.png"]];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.text = [[dbManager.databases objectAtIndex:[indexPath row]] objectForKey:kDatabaseName];
	}
	
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if([indexPath row] == [dbManager.databases count]){
		return UITableViewCellEditingStyleInsert;
	}
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if(self.tableView.editing && extraRows == 0){
		[self.tableView setEditing:NO animated:YES];
		[super setEditing:NO animated:YES];
	}
	[self.tableView setEditing:editing animated:animated];
	[super setEditing:editing animated:animated];
    self.tableView.allowsSelectionDuringEditing = YES;
	NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[dbManager.databases count] inSection:0]];
	if(editing){
		extraRows = 1;
		[[self tableView] insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
	} else {
		extraRows = 0;
		[[self tableView] deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
	}
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if([dbManager getDatabaseAtIndex:indexPath.row].isDirty){
            UIActionSheet *deleteSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes to this database that haven't been synced to DropBox yet. Are you sure you want to delete it?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
            deleteSheet.tag = 100 + indexPath.row;
            [deleteSheet showInView:self.view];
            [deleteSheet release];
        } else {
            [dbManager deleteDatabaseAtIndex:[indexPath row]];
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self gotoDropBox];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if([proposedDestinationIndexPath row] < [dbManager.databases count]){
		return proposedDestinationIndexPath;
	}
	return [NSIndexPath indexPathForRow:[dbManager.databases count]-1 inSection:0];
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	[dbManager moveDatabaseAtIndex:[fromIndexPath row] toIndex:[toIndexPath row]];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    if([indexPath row] < [dbManager.databases count]){
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[tableView cellForRowAtIndexPath:indexPath] isEditing]){
        if(indexPath.row < [dbManager.databases count]){
            EditDatabaseViewController *detailViewController = [[EditDatabaseViewController alloc] initWithNibName:@"EditDatabaseViewController" bundle:nil];
            detailViewController.database = [dbManager getDatabaseAtIndex:[indexPath row]];
            detailViewController.title = @"Details";
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
        } else {
            [self gotoDropBox];
        }
    } else {
        PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
        UIActionSheet *openMode;
        
        self.loadingDb = [dbManager getDatabaseAtIndex:[indexPath row]];
        self.loadingDb.delegate = self;
        
        switch(app.prefs.databaseOpenMode){
            case kOpenModeReadOnly:
                self.loadingDb.isReadOnly = YES;
                [self completeLoad];
                break;
            case kOpenModeWritable:
                [self completeLoad];
                break;
            case kOpenModeAlwaysAsk:
                openMode = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open Read-Only",@"Open Writable",nil];
                openMode.tag = 3;
                //[openMode showInView:self.view];
                [openMode showFromRect:[tableView cellForRowAtIndexPath:indexPath].frame  inView:self.view animated:YES];
                [openMode release];
                break;
        }
    }
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) completeLoad {
	self.loadingMessage = @"Updating";
	[self networkRequestStarted];
	
	[self.loadingDb update];
}

#pragma mark -
#pragma mark database delegate

- (void)databaseWasLockedForEditing:(id<Database>)database {
    database.dbManager.activeDatabase = database; // set the active database
	[self networkRequestStopped];
	KdbGroupViewController *gvc = [[KdbGroupViewController alloc] initWithNibName:@"KdbGroupViewController" bundle:nil];
	gvc.kdbGroup = [database rootGroup];
	gvc.title = database.name;
	[self.navigationController pushViewController:gvc animated:YES];
	[gvc release];
}

- (void)databaseWasAlreadyLocked:(id<Database>)database {
	[self networkRequestStopped];
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"This database has already been locked by another process." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Recover Lock" otherButtonTitles:@"Open Read-Only",nil];
	sheet.tag = 2;
    int row = [dbManager getIndexOfDatabase:database];
    if(row >= 0){
        [sheet showFromRect:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]].frame inView:self.view animated:YES];
    } else {
        [sheet showInView:self.view];
    }
	[sheet release];
}

- (void)database:(id<Database>)database failedToLockWithReason:(NSString*)reason {
	[self networkRequestStopped];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:reason delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)databaseUpdateComplete:(id<Database>)database {
	[self networkRequestStopped];
    alertMode = 3;
    unlocking = database;
	UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:@"Enter Password" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlock", nil];
    dialog.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [dialog show];
    [dialog release];
}

- (void)databaseUpdateWouldOverwriteChanges:(id<Database>)database {
    [self networkRequestStopped];
    alertMode = 4;
    unlocking = database;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Cancelled" message:@"The database on DropBox has changes that would overwrite changes in your local copy. Open the database in writable mode and use the sync button to choose which copy to keep." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)databaseWasDeleted:(id <Database>)database {
	[self networkRequestStopped];
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"This database has been deleted from your DropBox account. What would you like to do?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open Local Copy", nil];
	sheet.tag = 4;
	int row = [dbManager getIndexOfDatabase:database];
    if(row >= 0){
        [sheet showFromRect:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]].frame inView:self.view animated:YES];
    } else {
        [sheet showInView:self.view];
    }
	[sheet release];
}

- (void)database:(id<Database>)database updateFailedWithReason:(NSString*)error {
	[self networkRequestStopped];
	UIActionSheet *openMode = [[UIActionSheet alloc] initWithTitle:error delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Read Local Copy",nil];
	openMode.tag = 1;
	int row = [dbManager getIndexOfDatabase:database];
    if(row >= 0){
        [openMode showFromRect:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]].frame inView:self.view animated:YES];
    } else {
        [openMode showInView:self.view];
    }
	[openMode release];
}

- (void)databaseLockWasRemoved:(id<Database>)database {
    [self networkRequestStopped];
}

- (void)database:(id<Database>)database failedToRemoveLockWithReason:(NSString*)reason {
    [self networkRequestStopped];
    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The database lock was missing. It's possible that another instance recovered the lock and removed it already." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [error show];
    [error release];
}

#pragma mark -
#pragma mark ActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if(actionSheet.tag == 1){ //database update failed
		if(buttonIndex == 0){ // open read-only
			self.loadingDb.isReadOnly = YES;
			[self databaseUpdateComplete:self.loadingDb];
		}
	} else if(actionSheet.tag == 2){ // database was already locked
		if(buttonIndex == 0){ // recover lock
			[self databaseWasLockedForEditing:self.loadingDb];
		} else if(buttonIndex == 1){ // open read-only
			self.loadingDb.isReadOnly = YES;
			[self databaseWasLockedForEditing:self.loadingDb];
		}
	} else if(actionSheet.tag == 3){ // read only or writable mode database load
		if(buttonIndex == 0){ // read-only
			self.loadingDb.isReadOnly = YES;
			[self completeLoad];
		} else if(buttonIndex == 1){ // writable
			[self completeLoad];
		}
    } else if(actionSheet.tag == 4){ // database was deleted
        if(buttonIndex == 0){
			[self databaseUpdateComplete:self.loadingDb];
		}
	} else if(actionSheet.tag >= 100){
        if(buttonIndex == 0){
            int index = actionSheet.tag - 100;
            [dbManager deleteDatabaseAtIndex:index];
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark -
#pragma mark EnterPasswordDelegate

- (void)userUnlockedDatabase:(id<Database>)database {
    if(!database.isReadOnly) {
		self.loadingMessage = @"Locking";
        [self networkRequestStarted];
	
        self.loadingDb = database;
		[self.loadingDb lockForEditing];
	} else {
		[self databaseWasLockedForEditing:database];
	}
}



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[dbRootView release];
	[dbManager release];
	[loadingDb release];
	[settingsView release];
    [super dealloc];
}


@end

