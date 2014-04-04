//
//  KdbGroupViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KdbGroupViewController.h"


@implementation KdbGroupViewController

@synthesize kdbGroup;
@synthesize searchResults;
@synthesize savedSearchTerm;
@synthesize extraRows;
@synthesize extraSections;

PassDropAppDelegate *app;

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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
	if(!kdbGroup.database.isReadOnly){
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
	if([kdbGroup isRoot]){
		UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(removeLock)];
		self.navigationItem.leftBarButtonItem = backButton;
		[backButton release];
	}
    //self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
    [self performSelector:@selector(hideSearchBar) withObject:nil afterDelay:0.0f];
    self.tableView.alwaysBounceVertical = YES;
    
    if ([self savedSearchTerm])
    {
        [[[self searchDisplayController] searchBar] setText:[self savedSearchTerm]];
    }
    extraRows = 0;
    extraSections = 0;
    isDirty = NO;
    
    UIBarButtonItem *fspace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem *syncButton = [[[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStyleDone target:self action:@selector(syncButtonClicked:)] autorelease];
    syncButton.tintColor = [UIColor colorWithRed:0 green:0.75f blue:0 alpha:1];
    
    [self.navigationController toolbar].tintColor = [UIColor blackColor];
    [self setToolbarItems:[NSArray arrayWithObjects:fspace, syncButton, nil] animated:NO];
}

- (void)hideSearchBar {
    self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y + 44.0f); //self.searchDisplayController.searchBar.frame.size.height);
}

// hack to fix weird bug with the leftbarbuttonitems disappearing
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        UIBarButtonItem *sb = self.navigationItem.leftBarButtonItem;
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:sb.title style:sb.style target:sb.target action:sb.action] autorelease];
    }
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

- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    if(kdbGroup.database.isDirty && !kdbGroup.database.isReadOnly && !self.isEditing){
        [self showSyncButton];
    }
    [self.navigationController setDelegate:self];
}

- (void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && animated == YES){
        // close the currently viewed entry when user moves between groups (animated is false when fg/bg swapping)
        [(UINavigationController*)app.splitController.detailViewController popToRootViewControllerAnimated:NO];
    }
    [self.navigationController setDelegate:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.navigationController setDelegate:nil];
}

- (void)removeLock {
    [self.navigationController setToolbarHidden:YES animated:NO];
	if(!self.kdbGroup.database.isReadOnly){
        self.loadingMessage = @"Unlocking";
		[self networkRequestStarted];
		self.kdbGroup.database.delegate = self;
		[self.kdbGroup.database removeLock];
	} else {
		[self databaseLockWasRemoved:self.kdbGroup.database];
	}
}

#pragma mark - Sync button stuff

- (void)showSyncButton {
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)hideSyncButton {
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)syncButtonClicked:(id)sender {
    UIActionSheet *syncSheet = [[UIActionSheet alloc] initWithTitle:@"You have local changes that haven't been synced to DropBox yet." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard Changes" otherButtonTitles:@"Upload to DropBox", nil];
    syncSheet.tag = 1;
    //[syncSheet showInView:self.view];
    [syncSheet showFromBarButtonItem:(UIBarButtonItem*)sender animated:YES];
    [syncSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    UIAlertView *confirm;
    if(actionSheet.tag == 1){
        switch(buttonIndex){
            case 0: // revert
                confirm = [[UIAlertView alloc] initWithTitle:@"Revert Changes" message:@"The database will now close. The next time you open it, a fresh copy will be retrieved from DropBox. Continue?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
                confirm.tag = 2;
                [confirm show];
                [confirm release];
                break;
            case 1: // upload
                self.loadingMessage = @"Uploading";
                [self networkRequestStarted];
                kdbGroup.database.savingDelegate = self;
                [kdbGroup.database syncWithForce:NO];
                break;
            case 2: // cancel
                [self showSyncButton];
                break;
        }
    } else if(actionSheet.tag == 2){
        if(buttonIndex == 0){
            [self networkRequestStarted];
            [kdbGroup.database syncWithForce:YES];
        } else {
            [self showSyncButton];
        }
    }
}

- (void) pushNewDetailsView:(UIViewController*)newView disableMaster:(bool)disableMaster {
    if([newView isKindOfClass:[EditGroupViewController class]]){
        [(EditGroupViewController*)newView setMasterView:self];
    }
    if([newView isKindOfClass:[EditEntryViewController class]]){
        [(EditEntryViewController*)newView setMasterView:self];
    }
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [(UINavigationController*)app.splitController.detailViewController popToRootViewControllerAnimated:NO];
        [(UINavigationController*)app.splitController.detailViewController pushViewController:newView animated:NO];
        if(disableMaster){
            [self.navigationController.view setUserInteractionEnabled:NO];
            [UIView beginAnimations:nil context:NULL];
            [self.navigationController.view setAlpha:0.5];
            [UIView setAnimationDuration:0.3];
            [UIView commitAnimations];
            
        }
    } else {
        [self.navigationController pushViewController:newView animated:YES];
    }
}

#pragma mark -
#pragma mark Edit mode stuff

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    if(extraRows > 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1){
        return UITableViewCellEditingStyleInsert;
    }
	return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![kdbGroup.database isReadOnly];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    CGPoint offset = self.tableView.contentOffset;
	[self.tableView setEditing:editing animated:animated];
	[super setEditing:editing animated:animated];
    self.tableView.allowsSelectionDuringEditing = YES;
    NSArray *paths;
    if(kdbGroup.isRoot == NO){
        paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:[kdbGroup.subGroups count] inSection:0], [NSIndexPath indexPathForRow:[kdbGroup.entries count] inSection:1], nil];
    } else {
        paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:[kdbGroup.subGroups count] inSection:0], nil];
    }
    if(editing == YES){
        [self hideSyncButton];
        if([kdbGroup.subGroups count] == 0){
            extraSections++;
            [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
        if([kdbGroup.entries count] == 0 && kdbGroup.isRoot == NO){
            extraSections++;
            [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        }
        extraRows = 1;
        [[self tableView] insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    } else {
        extraRows = 0;
        [[self tableView] deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        
        int entrySection = 1;
        if([kdbGroup.subGroups count] == 0){
            extraSections--;
            [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            entrySection = 0;
        }
        if(kdbGroup.isRoot == NO){
            if([kdbGroup.entries count] == 0){
                extraSections--;
                [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:entrySection] withRowAnimation:UITableViewRowAnimationFade];
            }
            extraSections = 0;
        }
        if(isDirty == YES){
            self.loadingMessage = @"Saving";
            [self networkRequestStarted];
            
            kdbGroup.database.savingDelegate = self;
            [kdbGroup.database save];
        }
        if(kdbGroup.database.isDirty){
            [self showSyncButton];
        }
    }
    self.tableView.contentOffset = offset;
}

- (void)databaseSaveComplete:(id<Database>)database {
    [self networkRequestStopped];
    isDirty = NO;
    if(!self.isEditing){
        [self showSyncButton];
    }
}

- (void)database:(id<Database>)database saveFailedWithReason:(NSString *)error {
    [self networkRequestStopped];
    [self setWorking:NO];
    UIAlertView *saveError = [[UIAlertView alloc] initWithTitle:@"Save Failed" message:error delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    saveError.tag = 4;
    [saveError show];
    [saveError release];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)index {
	if(alertView.tag == 2){
        if(index == 1){
            // reverting changes
            [kdbGroup.database discardChanges];
            [self removeLock];
        } else {
            [self showSyncButton];
        }
    }
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL save = YES;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tableView beginUpdates];
        if(indexPath.section == 0 && (kdbGroup.subGroups.count > 0 || self.isEditing)){
            if(([kdbGroup.subGroups count] > 0 && !kdbGroup.isRoot) || ([kdbGroup.subGroups count] > 1 && kdbGroup.isRoot)){
                // delete group
                [kdbGroup deleteGroupAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                if(kdbGroup.subGroups.count == 0){
                    if(self.isEditing){
                        extraSections++; // if it was the last group we need to keep the group section in edit mode
                    } else {
                        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
                    }
                }
            } else if(kdbGroup.isRoot) {
                UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You can't delete the last group in a database." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [error show];
                [error release];
                save = NO;
            }
        } else {
            if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                // remove the entry they're viewing if it's the one they just deleted
                NSArray *details = [(UINavigationController*)app.splitController.detailViewController viewControllers];
                if([details count] > 1){
                    UIViewController *curEntry = [details objectAtIndex:1];
                    if([curEntry isKindOfClass:[KdbEntryViewController class]] && [(KdbEntryViewController*)curEntry kdbEntry] == [kdbGroup.entries objectAtIndex:indexPath.row]){
                        [(UINavigationController*)app.splitController.detailViewController popToRootViewControllerAnimated:NO];
                    }
                }
            }
            // delete entry
            [kdbGroup deleteEntryAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if(kdbGroup.entries.count == 0){
                if(self.isEditing){
                    extraSections++;
                } else {
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
        }
        [self.tableView endUpdates];
        if(save){
            self.loadingMessage = @"Saving";
            [self networkRequestStarted];
            
            kdbGroup.database.savingDelegate = self;
            [kdbGroup.database save];
        }
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        if([indexPath section] == 0){
            EditGroupViewController *egvc = [[EditGroupViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
            egvc.title = @"Add Group";
            egvc.kdbGroup = kdbGroup;
            egvc.editMode = NO;
            [self pushNewDetailsView:egvc disableMaster:YES];
            [egvc release];
        } else {
            EditEntryViewController *eevc = [[EditEntryViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
            eevc.title = @"Add Entry";
            eevc.parentGroup = kdbGroup;
            eevc.editMode = NO;
            [self pushNewDetailsView:eevc disableMaster:YES];
            [eevc release];
        }
    }   
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	switch(sourceIndexPath.section){
        case 0:
            if(proposedDestinationIndexPath.section == 1 || proposedDestinationIndexPath.row >= kdbGroup.subGroups.count){
                return [NSIndexPath indexPathForRow:kdbGroup.subGroups.count - 1 inSection:0];
            }
            break;
        case 1:
            if(proposedDestinationIndexPath.section == 0){
                return [NSIndexPath indexPathForRow:0 inSection:1];
            } else if (proposedDestinationIndexPath.row >= kdbGroup.entries.count) {
                return [NSIndexPath indexPathForRow:kdbGroup.entries.count - 1 inSection:1];
            }
            break;
    }
    return proposedDestinationIndexPath;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    switch(fromIndexPath.section){
        case 0:
            [kdbGroup moveSubGroupFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
            break;
        case 1:
            [kdbGroup moveEntryFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
            break;
    }
    isDirty = YES;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
	switch(indexPath.section){
        case 0:
            if(kdbGroup.subGroups.count > 0 || extraSections > 0)
                return indexPath.row < kdbGroup.subGroups.count;
            else
                return indexPath.row < kdbGroup.entries.count;
            break;
        case 1:
            return indexPath.row < kdbGroup.entries.count;
            break;
    }
    return NO;
}

#pragma mark -
#pragma mark DatabaseDelegate

- (void)databaseLockWasRemoved:(id<Database>)database {
    database.dbManager.activeDatabase = nil;
	[self networkRequestStopped];
	[self.navigationController popToRootViewControllerAnimated:YES];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [(UINavigationController*)app.splitController.detailViewController popToRootViewControllerAnimated:NO];
    }
}

- (void)database:(id<Database>)database failedToRemoveLockWithReason:(NSString*)reason {
    database.dbManager.activeDatabase = nil;
	[self networkRequestStopped];
	UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:reason delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
	[error show];
	[error release];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)database:(id<Database>)db syncFailedWithReason:(NSString*)error {
    [self networkRequestStopped];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)databaseSyncComplete:(id<Database>)db {
    [self networkRequestStopped];
    [self hideSyncButton];
}

- (void)databaseSyncWouldOverwriteChanges:(id<Database>)db {
    [self networkRequestStopped];
    // show sliding alert asking if they want to overwrite remote changes
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"The database on DropBox has already been modified. Do you want to overwrite the newer file with this one?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Upload to DropBox" otherButtonTitles:nil];
    sheet.tag = 2;
    //[sheet showInView:self.view];
    [sheet showFromBarButtonItem:(UIBarButtonItem*)[self.toolbarItems objectAtIndex:1] animated:YES];
    [sheet release];
}

- (void)databaseWasDeleted:(id<Database>)db {
    [self networkRequestStopped];
    // show sliding alert asking if they want to upload it
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"The database has been deleted from your DropBox account. Do you want to upload this file anyway?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Upload to DropBox", nil];
    sheet.tag = 2;
    //[sheet showInView:self.view];
    [sheet showFromBarButtonItem:(UIBarButtonItem*)[self.toolbarItems objectAtIndex:1] animated:YES];
    [sheet release];
}

#pragma mark -
#pragma mark tableview delegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:1];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[tableView cellForRowAtIndexPath:indexPath] isEditing]){
        if(indexPath.section == 0 && indexPath.row < [kdbGroup.subGroups count]){
            // edit group
            KdbGroup *cellGroup = [kdbGroup.subGroups objectAtIndex:[indexPath row]];
            EditGroupViewController *egvc = [[EditGroupViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
            egvc.title = cellGroup.groupName;
            egvc.kdbGroup = cellGroup;
            egvc.editMode = YES;
            [self pushNewDetailsView:egvc disableMaster:YES];
            [egvc release];
        } else if(indexPath.section == 1 && indexPath.row < [kdbGroup.entries count]){
            // edit entry
            KdbEntry *cellEntry = [kdbGroup.entries objectAtIndex:[indexPath row]];
            EditEntryViewController *eevc = [[EditEntryViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
            eevc.title = cellEntry.entryName;
            eevc.kdbEntry = cellEntry;
            eevc.parentGroup = cellEntry.parent;
            eevc.editMode = YES;
            [self pushNewDetailsView:eevc disableMaster:YES];
            [eevc release];
        } else {
            [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
        }
    } else {
        if(tableView == [[self searchDisplayController] searchResultsTableView]){
            KdbEntry *searchEntry = [searchResults objectAtIndex:[indexPath row]];
            KdbEntryViewController *svc = [[KdbEntryViewController alloc] initWithNibName:@"KdbEntryViewController" bundle:nil];
            svc.title = searchEntry.entryName;
            svc.kdbEntry = searchEntry;
            [self pushNewDetailsView:svc disableMaster:NO];
            [svc release];
        } else {
            if([indexPath section] == 0 && [kdbGroup.subGroups count] > 0){
                // selected a group
                KdbGroup *cellGroup = [kdbGroup.subGroups objectAtIndex:[indexPath row]];
                KdbGroupViewController *gvc = [[KdbGroupViewController alloc] initWithNibName:@"KdbGroupViewController" bundle:nil];
                gvc.title = cellGroup.groupName;
                gvc.kdbGroup = cellGroup;
                [self.navigationController pushViewController:gvc animated:YES];
                [gvc release];
            } else {
                // selected an entry
                KdbEntry *cellEntry = [kdbGroup.entries objectAtIndex:[indexPath row]];
                KdbEntryViewController *evc = [[KdbEntryViewController alloc] initWithNibName:@"KdbEntryViewController" bundle:nil];
                evc.title = cellEntry.entryName;
                evc.kdbEntry = cellEntry;
                [self pushNewDetailsView:evc disableMaster:NO];
                [evc release];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) reloadSection:(int)section {
    // reset the extrasections variable before reloading the section (in case it was on a delete or new group/entry)
    if(self.isEditing){
        extraSections = 0;
        if(kdbGroup.entries.count == 0 && !kdbGroup.isRoot){
            extraSections++;
        }
        if(kdbGroup.subGroups.count == 0){
            extraSections++;
        }
    } else {
        extraSections = 0;
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? UITableViewRowAnimationFade : UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == [[self searchDisplayController] searchResultsTableView]){
        return 1;
    } else {
        int sections = 0;
        if([kdbGroup.subGroups count] > 0){
            sections++;
        }
        if([kdbGroup.entries count] > 0){
            sections++;
        }
        return sections + extraSections;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == [[self searchDisplayController] searchResultsTableView]){
        if(self.searchResults){
            return [self.searchResults count];
        }
        return 0;
    } else {
        switch(section){
            case 0:
                if([kdbGroup.subGroups count] > 0 || extraSections > 0){
                    return [kdbGroup.subGroups count] + extraRows;
                } else {
                    return [kdbGroup.entries count] + extraRows;
                }
                break;
            case 1:
                if(kdbGroup.isRoot == NO){
                    return [kdbGroup.entries count] + extraRows;
                } else {
                    return 0;
                }
                break;
        }
    }
	return 0 + extraRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView != [[self searchDisplayController] searchResultsTableView]){
        switch(section){
            case 0:
                if([kdbGroup.subGroups count] > 0 || extraSections > 0){
                    return @"Groups";
                } else {
                    return @"Entries";
                }
                break;
            case 1:
                return @"Entries";
                break;
        }
    }
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    if(tableView == [[self searchDisplayController] searchResultsTableView]){
        KdbEntry *searchEntry = [self.searchResults objectAtIndex:[indexPath row]];
        cell.textLabel.text = [searchEntry entryName];
        [cell.imageView setImage:[searchEntry entryIcon]];
    } else {
        BOOL groupCell = NO;
        if(extraSections > 0){
            if(indexPath.section == 0){
                groupCell = YES;
            }
        } else {
            if([kdbGroup.subGroups count] > 0 && indexPath.section == 0){
                groupCell = YES;
            }
        }
        if(groupCell == YES && [indexPath row] < [kdbGroup.subGroups count]){
            KdbGroup *cellGroup = [kdbGroup.subGroups objectAtIndex:[indexPath row]];
            cell.textLabel.text = [cellGroup groupName];
            [cell.imageView setImage:[cellGroup groupIcon]];
        } else if(groupCell == NO && [indexPath row] < [kdbGroup.entries count]) {
            KdbEntry *cellEntry = [kdbGroup.entries objectAtIndex:[indexPath row]];
            cell.textLabel.text = [cellEntry entryName];
            [cell.imageView setImage:[cellEntry entryIcon]];
        } else {
            [[cell imageView] setImage:nil];
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(groupCell == YES){
                cell.textLabel.text = @"Add Group";
            } else {
                cell.textLabel.text = @"Add Entry";
            }
        }
    }
	
	return cell;
}

#pragma mark -
#pragma mark search stuff

- (BOOL)kdbEntry:(KdbEntry*)entry isMatchForTerm:(NSString*)searchTerm {
    if([[[entry entryName] lowercaseString] rangeOfString:[searchTerm lowercaseString]].location != NSNotFound){
        return YES;
    }
    if([[[entry entryUsername] lowercaseString] rangeOfString:[searchTerm lowercaseString]].location != NSNotFound){
        return YES;
    }
    if([[[entry entryUrl] lowercaseString] rangeOfString:[searchTerm lowercaseString]].location != NSNotFound){
        return YES;
    }
    if([[[entry entryNotes] lowercaseString] rangeOfString:[searchTerm lowercaseString]].location != NSNotFound){
        return YES;
    }
    return NO;
}

-(NSArray*)getMatchingEntriesFromGroup:(KdbGroup*)group forSearchTerm:(NSString*)searchTerm {
    PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray *matches = [[[NSMutableArray alloc] init] autorelease];
    
    for(int i = 0; i < [group.entries count]; i++){
        if([self kdbEntry:[group.entries objectAtIndex:i] isMatchForTerm:searchTerm] && ![matches containsObject:[group.entries objectAtIndex:i]]){
            [matches addObject:[group.entries objectAtIndex:i]];
        }
    }
    for(int i = 0; i < [group.subGroups count]; i++){
        if(!kdbGroup.isRoot || !app.prefs.ignoreBackup || ![[(KdbGroup*)[group.subGroups objectAtIndex:i] groupName] isEqualToString:@"Backup"]){
            [matches addObjectsFromArray:[self getMatchingEntriesFromGroup:[group.subGroups objectAtIndex:i] forSearchTerm:searchTerm]];
        }
    }
    
    return matches;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if(searchResults){
        [searchResults removeAllObjects];
    } else {
        self.searchResults = [[[NSMutableArray alloc] init] autorelease];
    }
    [self.searchResults addObjectsFromArray:[self getMatchingEntriesFromGroup:kdbGroup forSearchTerm:searchString]];
    
    return YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [savedSearchTerm release];
    savedSearchTerm = nil;
    [self.tableView reloadData];
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
    self.searchDisplayController.delegate = nil;
    self.searchDisplayController.searchResultsDelegate = nil;
    self.searchDisplayController.searchResultsDataSource = nil;
    [savedSearchTerm release];
    if(searchResults){
        [searchResults removeAllObjects];
        [searchResults release];
    }
    [super dealloc];
}


@end
