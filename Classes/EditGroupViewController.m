//
//  EditGroupViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditGroupViewController.h"


@implementation EditGroupViewController

@synthesize kdbGroup;
@synthesize parentGroup;
@synthesize editMode;
@synthesize neuIcon;
@synthesize newIconId;
@synthesize neuName;
@synthesize masterView;
@synthesize iconPop;

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

PassDropAppDelegate *app;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveGroup)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
    if(editMode == YES){
        self.parentGroup = kdbGroup.parent;
        self.neuIcon = [kdbGroup groupIcon];
        self.neuName = [kdbGroup groupName];
    } else {
        self.parentGroup = kdbGroup;
        if(self.parentGroup.isRoot){
            self.neuIcon = [UIImage imageNamed:@"0.png"];
        } else {
            self.neuIcon = self.parentGroup.groupIcon;
        }
        self.neuName = @"";
    }
    newIconId = NO_ICON_SET;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        UIBarButtonItem *closeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonClicked)] autorelease];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    oldkeyboardHeight = 0;
    keyboardShowing = NO;
}

// hack to fix weird bug with the leftbarbuttonitems disappearing
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        UIBarButtonItem *sb = self.navigationItem.leftBarButtonItem;
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:sb.title style:sb.style target:sb.target action:sb.action] autorelease];
    }
}

- (void)closeButtonClicked {
    [self.navigationController popViewControllerAnimated:NO];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [UIView beginAnimations:nil context:NULL];
        [app.splitController.masterViewController.view setAlpha:1];
        [UIView setAnimationDuration:0.3];
        [UIView commitAnimations];
        
        [app.splitController.masterViewController.view setUserInteractionEnabled:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self hideKeyboard];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self hideKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [iconPop dismissPopoverAnimated:YES];
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

- (void) keyboardWillShow:(NSNotification*)note {
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    int keyboardHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? keyboardBounds.size.height : keyboardBounds.size.width;
    if(keyboardShowing == NO){
        keyboardShowing = YES;
        CGRect frame = self.view.frame;
        frame.size.height -= keyboardHeight;
        
        oldkeyboardHeight = keyboardHeight;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        self.view.frame = frame;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
        [UIView commitAnimations];
    }
}

- (void) keyboardWillHide:(NSNotification*)note {
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBounds];
    int keyboardHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? keyboardBounds.size.height : keyboardBounds.size.width;
    if(keyboardShowing == YES){
        keyboardShowing = NO;
        CGRect frame = self.view.frame;
        frame.size.height += keyboardHeight;
        
        oldkeyboardHeight = 0;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        self.view.frame = frame;
        [UIView commitAnimations];
    }
}

#pragma mark - actions

- (void)parentGroupSelected:(KdbGroup *)group {
    self.parentGroup = group;
    [[self tableView] reloadData];
}

- (UIViewController *)viewController {
    return self;
}

- (KdbGroup*)childGroup {
    return kdbGroup;
}

- (void)iconSelected:(UIImage*)icon withId:(uint32_t)iconId {
    self.neuIcon = icon;
    self.newIconId = iconId;
    [[self tableView] reloadData];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [iconPop dismissPopoverAnimated:YES];
    }
}

- (void)hideKeyboard {
    UITextField *fld = (UITextField*)[self.view viewWithTag:currentFirstResponder];
    [fld resignFirstResponder];
}

#pragma mark - Saving

- (void)saveGroup {
    // clear ui stuff
    [[self.view viewWithTag:55] resignFirstResponder];
    
    // input validation
    if([neuName length] == 0){
        UIAlertView *invalid = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must enter a group name." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        invalid.tag = 3;
		[invalid show];
		[invalid release];
    } else {
        uint32_t iconId;
        if(newIconId != NO_ICON_SET){
            iconId = newIconId;
        } else {
            if(editMode == YES){
                iconId = [kdbGroup kpGroup]->image_id;
            } else {
                if(self.parentGroup.isRoot){
                    iconId = 0;
                } else {
                    iconId = [self.parentGroup kpGroup]->image_id;
                }
            }
        }
        
        if(self.editMode == YES){
            [kdbGroup updateWithParent:parentGroup withTitle:neuName withIcon:iconId];
        } else {
            kdbGroup = [[KdbGroup alloc] initWithParent:parentGroup withTitle:neuName withIcon:iconId forDatabase:parentGroup.database];
        }
        
        self.loadingMessage = @"Saving";
        [self networkRequestStarted];
        
        kdbGroup.database.savingDelegate = self;
        [kdbGroup.database save];
    }
}

- (void)databaseSaveComplete:(id<Database>)database {
    [self networkRequestStopped];
    [masterView reloadSection:0];
    [self.navigationController popViewControllerAnimated:[[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [UIView beginAnimations:nil context:NULL];
        [app.splitController.masterViewController.view setAlpha:1];
        [UIView setAnimationDuration:0.3];
        [UIView commitAnimations];
        
        [app.splitController.masterViewController.view setUserInteractionEnabled:YES];
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

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)index {
	
}

#pragma mark -
#pragma mark tableviewdatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section){
        case 0:
            return 1;
            break;
        case 1:
            return 2;
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section){
        case 0:
            return @"Parent Group";
        case 1:
            return @"Group Name";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *NameCellIdentifier = @"NameCell";
    NSString *identifier;
    
    if(indexPath.section == 1){
        identifier = NameCellIdentifier;
    } else {
        identifier = CellIdentifier;
    }
    
	UITableViewCell *cell;
    UITextField *field;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
        if(indexPath.section == 1 && indexPath.row == 0){
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            int offset;
            if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
                ([UIScreen mainScreen].scale == 2.0)) {
                offset = 47;
            } else {
                offset = 36;
            }
            field = [[UITextField alloc] initWithFrame:CGRectMake(offset, 0, cell.contentView.frame.size.width - offset, cell.contentView.frame.size.height)];
            field.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            field.tag = 55;
            [cell.contentView addSubview:field];
            
            [field release];
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    switch(indexPath.section){
        case 0:
            if(parentGroup.isRoot == YES){
                [cell.imageView setImage:nil];
                cell.textLabel.text = @"None";
            } else {
                [cell.imageView setImage:[parentGroup groupIcon]];
                cell.textLabel.text = [parentGroup groupName];
            }
            break;
        case 1:
            switch(indexPath.row){
                case 0:
                    field = (UITextField*)[cell viewWithTag:55];
                    
                    field.text = neuName;
                    field.font = [UIFont boldSystemFontOfSize:17];
                    
                    field.adjustsFontSizeToFitWidth = YES;
                    field.placeholder = @"Required";
                    field.keyboardType = UIKeyboardTypeDefault;
                    field.returnKeyType = UIReturnKeyDone;
                    field.clearButtonMode = UITextFieldViewModeWhileEditing;
                    field.delegate = self;
                    
                    [cell.imageView setImage:neuIcon];
                    cell.textLabel.text = @"";
                    break;
                case 1:
                    [cell.imageView setImage:nil];
                    cell.textLabel.text = @"Choose Icon";
                    break;
            }
            break;
    }
    
    return cell;
}

#pragma mark -
#pragma mark tableviewdelegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:1];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 1 && [indexPath row] == 0){
		[[self.view viewWithTag:55] becomeFirstResponder];
        return nil;
	}
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath section] == 0){
        ParentGroupPicker *pgp = [[ParentGroupPicker alloc] initWithNibName:@"KdbGroupViewController" bundle:nil];
        pgp.title = @"Select Parent";
        pgp.kdbGroup = [kdbGroup.database rootGroup];
        pgp.delegate = self;
        pgp.showNone = YES;
        [self.navigationController pushViewController:pgp animated:YES];
        [pgp release];
    } else if(indexPath.section == 1 && indexPath.row == 1){
        [self hideKeyboard];
        IconPicker *ip = [[IconPicker alloc] initWithNibName:@"ChooseIconView" bundle:nil];
        ip.delegate = self;
        
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            ip.contentSizeForViewInPopover = CGSizeMake(320, 416);
            self.iconPop = [[[UIPopoverController alloc] initWithContentViewController:ip] autorelease];
            [iconPop presentPopoverFromRect:[tableView cellForRowAtIndexPath:indexPath].frame inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            UINavigationController *navBar = [[UINavigationController alloc] initWithRootViewController:ip];
            [self.navigationController presentModalViewController:navBar animated:YES];
            [navBar release];
        }
        [ip release];
    }
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
	return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentFirstResponder = textField.tag;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(textField.tag == 55){
		self.neuName = textField.text;
	}
    currentFirstResponder = 0;
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
    [parentGroup release];
    [neuIcon release];
    [neuName release];
    [iconPop release];
    [super dealloc];
}


@end
