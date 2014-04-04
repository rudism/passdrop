//
//  EditDatabaseViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditDatabaseViewController.h"


@implementation EditDatabaseViewController

@synthesize database;
@synthesize neuName;
@synthesize oldPassword;
@synthesize neuPassword;
@synthesize verifyPassword;
@synthesize scrollToPath;

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
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonClicked)];
	self.navigationItem.rightBarButtonItem = saveButton;
	[saveButton release];
	self.neuName = [NSString stringWithString:database.name];
    oldkeyboardHeight = 0;
    keyboardShowing = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self hideKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) keyboardWillShow:(NSNotification*)note {
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    int keyboardHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? keyboardBounds.size.height : keyboardBounds.size.width;
    if(keyboardShowing == NO){
        keyboardShowing = YES;
        CGRect frame = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? self.navigationController.view.frame : self.view.frame;
        frame.size.height -= keyboardHeight;
        
        oldkeyboardHeight = keyboardHeight;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            self.navigationController.view.frame = frame;
        } else {
            self.view.frame = frame;
        }
        [self.tableView scrollToRowAtIndexPath:scrollToPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        [UIView commitAnimations];
    } else if(keyboardHeight != oldkeyboardHeight){
        int diff = keyboardHeight - oldkeyboardHeight;
        CGRect frame = self.view.frame;
        frame.size.height -= diff;
        
        oldkeyboardHeight = keyboardHeight;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        self.view.frame = frame;
        [self.tableView scrollToRowAtIndexPath:scrollToPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        [UIView commitAnimations];
    }
}

- (void) keyboardWillHide:(NSNotification*)note {
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBounds];
    int keyboardHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? keyboardBounds.size.height : keyboardBounds.size.width;
    if(keyboardShowing == YES){
        keyboardShowing = NO;
        CGRect frame = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? self.navigationController.view.frame : self.view.frame;
        frame.size.height += keyboardHeight;
        
        oldkeyboardHeight = 0;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            self.navigationController.view.frame = frame;
        } else {
            self.view.frame = frame;
        }
        [UIView commitAnimations];
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

#pragma mark -
#pragma mark Actions

- (void) saveButtonClicked {
    [(UITextField*)[self.view viewWithTag:55] resignFirstResponder];
    [(UITextField*)[self.view viewWithTag:56] resignFirstResponder];
    [(UITextField*)[self.view viewWithTag:57] resignFirstResponder];
    [(UITextField*)[self.view viewWithTag:58] resignFirstResponder];
    
	// validate title field
	if(neuName.length == 0){
		[self showError:@"You must enter a title for the database."];
        [(UITextField*)[self.view viewWithTag:55] becomeFirstResponder];
		return;
	}
	
	if(![database.name isEqualToString:neuName]){
		database.name = neuName;
		PassDropAppDelegate *app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
		[app.dbManager updateDatabase:database];
	}
	
    if(neuPassword.length > 0 || verifyPassword.length > 0){
        if(oldPassword == nil || oldPassword.length == 0){
            [self showError:@"You must enter your old password to set a new one."];
            [(UITextField*)[self.view viewWithTag:56] becomeFirstResponder];
            return;
        }
        if(![neuPassword isEqualToString:verifyPassword]){
            [self showError:@"The new passwords you entered did not match."];
            [(UITextField*)[self.view viewWithTag:57] becomeFirstResponder];
            return;
        }
        if(![database loadWithPassword:oldPassword]){
            [self showError:@"Could not decrypt the database. Please verify your old password and try again."];
            return;
        }
        database.savingDelegate = self;
        [database saveWithPassword:neuPassword];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) showError:(NSString*)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)hideKeyboard {
    UITextField *fld = (UITextField*)[self.view viewWithTag:currentFirstResponder];
    [fld resignFirstResponder];
}

#pragma mark - Database delegate

- (void)database:(id<Database>)database saveFailedWithReason:(NSString*)error{
    [self showError:error];
}

- (void)databaseSaveComplete:(id<Database>)db{
    self.loadingMessage = @"Uploading";
    [self networkRequestStarted];
    [db syncWithForce:NO];
}

- (void)database:(id<Database>)db syncFailedWithReason:(NSString*)error {
    [self networkRequestStopped];
    [self showError:error];
}

- (void)databaseSyncComplete:(id<Database>)db {
    [self networkRequestStopped];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)databaseSyncWouldOverwriteChanges:(id<Database>)db {
    [self networkRequestStopped];
    // show sliding alert asking if they want to overwrite remote changes
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"The database on DropBox has already been modified. Do you want to overwrite the newer file with this one?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Upload to DropBox" otherButtonTitles:nil];
    [sheet showInView:self.view];
    [sheet release];
}

- (void)databaseWasDeleted:(id<Database>)db {
    [self networkRequestStopped];
    // show sliding alert asking if they want to upload it
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"The database has been deleted from your DropBox account. Do you want to upload this file anyway?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Upload to DropBox", nil];
    [sheet showInView:self.view];
    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0){
        [self networkRequestStarted];
        [database syncWithForce:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sync Cancelled" message:@"The password on your local copy has been changed, but has not yet been synced to DropBox." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        [alert release];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark Table Data

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return 1;
			break;
		case 1:
			return 3;
			break;
		case 2:
			return 3;
			break;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return @"Database Name";
			break;
		case 1:
			return @"Change Password";
			break;
		case 2:
			return @"Details";
			break;
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *DetailCellIdentifier = @"CellDetail";
	static NSString *PasswordCellIdentifier = @"CellPw";
	static NSString *LocationCellIdentifier = @"CellLoc";
	static NSString *TitleCellIdentifier = @"CellTitle";
    UITableViewCell *cell = nil;
	UITextField *field;
	
	switch([indexPath section]){
		case 0:
			cell = [tableView dequeueReusableCellWithIdentifier:TitleCellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TitleCellIdentifier] autorelease];
				field = [[UITextField alloc] initWithFrame:CGRectMake(11, 0, cell.contentView.frame.size.width - 11, cell.contentView.frame.size.height)];
				field.tag = 55;
				field.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
				[cell.contentView addSubview:field];
				[field release];
			}
			
			// set up title field
			field = (UITextField*)[cell viewWithTag:55];
			
			field.text = database.name;
			field.font = [UIFont boldSystemFontOfSize:17];

			field.adjustsFontSizeToFitWidth = YES;
			field.placeholder = @"Required";
			field.keyboardType = UIKeyboardTypeDefault;
			field.returnKeyType = UIReturnKeyDone;
            field.clearButtonMode = UITextFieldViewModeWhileEditing;
			field.delegate = self;
			
			break;
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:PasswordCellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PasswordCellIdentifier] autorelease];
                field = [[UITextField alloc] initWithFrame:CGRectMake(11, 0, cell.contentView.frame.size.width - 11, cell.contentView.frame.size.height)];
                field.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
				[cell.contentView addSubview:field];
				[field release];
			}
            
            field = nil;
            for(int i = 0; i < cell.contentView.subviews.count; i++){
                if([[cell.contentView.subviews objectAtIndex:i] isKindOfClass:[UITextField class]]){
                    field = (UITextField*)[cell.contentView.subviews objectAtIndex:i];
                    break;
                }
            }
			
			// set up password fields
			field.tag = 56 + [indexPath row];
			
			field.font = [UIFont boldSystemFontOfSize:17];
			
			field.adjustsFontSizeToFitWidth = YES;
            field.returnKeyType = UIReturnKeyDone;
			switch(indexPath.row){
                case 0:
                    field.placeholder = @"Old Password";
                    break;
                case 1:
                    field.placeholder = @"New Password";
                    break;
                case 2:
                    field.placeholder = @"Verify New Password";
                    break;
			}
			field.keyboardType = UIKeyboardTypeDefault;
			field.secureTextEntry = YES;
			field.clearButtonMode = UITextFieldViewModeWhileEditing;
			field.delegate = self;
			
			break;
		case 2:
			if([indexPath row] == 0){
				cell = [tableView dequeueReusableCellWithIdentifier:LocationCellIdentifier];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:LocationCellIdentifier] autorelease];
				}
			} else {
				cell = [tableView dequeueReusableCellWithIdentifier:DetailCellIdentifier];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DetailCellIdentifier] autorelease];
				}
			}
			
			// set up detail fields
			
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			
			switch([indexPath row]){
				case 0:
					cell.textLabel.text = @"Location";
					cell.detailTextLabel.text = [database location];
					break;
				case 1:
					cell.textLabel.text = @"Modified";
					cell.detailTextLabel.text = [formatter stringFromDate:database.lastModified];
					break;
				case 2:
					cell.textLabel.text = @"Synced";
					cell.detailTextLabel.text = [formatter stringFromDate:database.lastSynced];
					break;
			}
			
			[formatter release];
			
			break;
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table Delegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:10];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// only location is selectable
	if([indexPath section] == 2 && [indexPath row] == 0){
		//return indexPath;
        return nil;
	} else {
		// if it's title or a password cell, set focus to the textfield
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		if([cell viewWithTag:55] != nil){
			[[cell viewWithTag:55] becomeFirstResponder];
		} else if([cell viewWithTag:56] != nil){
			[[cell viewWithTag:56] becomeFirstResponder];
		} else if([cell viewWithTag:57] != nil){
			[[cell viewWithTag:57] becomeFirstResponder];
		} else if([cell viewWithTag:58] != nil){
            [[cell viewWithTag:58] becomeFirstResponder];
        }
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// only location cell is selectable so don't need to check anything here
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location" message:[[tableView cellForRowAtIndexPath:indexPath] detailTextLabel].text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 2 && [indexPath row] == 0){ // need modified height for location cell
		return 64;
	}
	return 44;
}

#pragma mark -
#pragma mark TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self hideKeyboard];
	return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentFirstResponder = textField.tag;
    self.scrollToPath = [NSIndexPath indexPathForRow:textField.tag > 55 ? textField.tag - 56 : 0 inSection:textField.tag == 55 ? 0 : 1];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	switch(textField.tag){
        case 55:
            self.neuName = textField.text;
            break;
        case 56:
            self.oldPassword = textField.text;
            break;
        case 57:
            self.neuPassword = textField.text;
            break;
        case 58:
            self.verifyPassword = textField.text;
            break;
	}
    
    currentFirstResponder = 0;
}

#pragma mark -
#pragma mark Memory Management

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
	[neuName release];
	[database release];
    [neuPassword release];
    [verifyPassword release];
    [scrollToPath release];
    [super dealloc];
}


@end
