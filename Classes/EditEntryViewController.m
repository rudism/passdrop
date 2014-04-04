//
//  EditEntryViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditEntryViewController.h"

@implementation EditEntryViewController

@synthesize parentGroup;
@synthesize kdbEntry;
@synthesize editMode;
@synthesize neuName;
@synthesize neuIcon;
@synthesize neuIconId;
@synthesize neuUsername;
@synthesize neuPassword;
@synthesize verifyPassword;
@synthesize neuUrl;
@synthesize neuNotes;
@synthesize neuExpireDate;
@synthesize masterView;
@synthesize iconPop;
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

UIDatePicker *datePicker;
UIToolbar *dateBar;
PassDropAppDelegate *app;

- (NSDate*)neverExpires {
    NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents *date = [[NSDateComponents alloc] init];
    [date setCalendar:gregorian];
    [date setDay:31];
    [date setMonth:12];
    [date setYear:2999];
    [date setHour:23];
    [date setMinute:59];
    [date setSecond:59];
    NSDate *retVal = [date date];
    [date release];
    return retVal;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveEntry)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
    currentFirstResponder = 0;
    
    self.neuPassword = @"";
    self.verifyPassword = @"";
    
    datePicker = [[[UIDatePicker alloc] init] retain];
    if([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad){
        datePicker.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    
    dateBar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)] retain];
    dateBar.barStyle = UIBarStyleBlackTranslucent;
    dateBar.tintColor = [UIColor lightGrayColor];
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(hideKeyboard)] autorelease];
    UIBarButtonItem *fspace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithTitle:@"Choose" style:UIBarButtonItemStyleDone target:self action:@selector(chooseButtonClicked)] autorelease];
    
    [dateBar setItems:[NSArray arrayWithObjects:cancelButton, fspace, doneButton, nil]];
    
    neuIconId = NO_ICON_SET;
    self.tableView.autoresizesSubviews = YES;
    
    if(editMode == YES){
        self.neuIcon = [kdbEntry entryIcon];
        self.neuName = [kdbEntry entryName];
        self.neuUsername = [kdbEntry entryUsername];
        self.neuUrl = [kdbEntry entryUrl];
        self.neuNotes = [kdbEntry entryNotes];
        self.neuExpireDate = [kdbEntry expireDate];
    } else {
        self.neuIcon = [parentGroup groupIcon]; //[UIImage imageNamed:@"0.png"];
        self.neuName = @"";
        self.neuUsername = @"";
        self.neuUrl = @"";
        self.neuNotes = @"";
        self.neuExpireDate = [self neverExpires];
    }
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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

#pragma mark - actions

- (void)parentGroupSelected:(KdbGroup *)group {
    self.parentGroup = group;
    [[self tableView] reloadData];
}

- (KdbGroup*)childGroup {
    return nil;
}

- (void)passwordGenerated:(NSString*)password {
    self.neuPassword = password;
    self.verifyPassword = password;
    [self.tableView reloadData];
}

- (UIViewController *)viewController {
    return self;
}

- (void)iconSelected:(UIImage*)icon withId:(uint32_t)iconId {
    self.neuIcon = icon;
    self.neuIconId = iconId;
    [[self tableView] reloadData];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [iconPop dismissPopoverAnimated:YES];
    }
}

- (void)hideKeyboard {
    UIView *fld = [self.view viewWithTag:currentFirstResponder];
    [fld resignFirstResponder];
    [self.view endEditing:YES];
}

#pragma mark - DatePicker stuff

-(void)chooseButtonClicked {
    self.neuExpireDate = [datePicker date];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:6]] withRowAnimation:UITableViewRowAnimationNone];
    [self hideKeyboard];
}

#pragma mark - Saving

- (void)saveEntry {
    // clear ui stuff
    //[self closeDatePicker];
    [self hideKeyboard];
    
    // input validation
    if(neuName.length == 0){
        UIAlertView *invalid = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must enter an entry name." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
		[invalid show];
		[invalid release];
    } else if([neuPassword isEqualToString:verifyPassword] == NO){
        UIAlertView *invalid = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The passwords you entered do not match." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
		[invalid show];
		[invalid release];
    } else {
        uint32_t iconId;
        if(neuIconId != NO_ICON_SET){
            iconId = neuIconId;
        } else {
            if(editMode == YES){
                iconId = [kdbEntry kpEntry]->image_id;
            } else {
                iconId = [parentGroup kpGroup]->image_id;
            }
        }
        
        if(self.editMode == YES){
            NSString *setPassword = neuPassword;
            if(neuPassword.length == 0){
                setPassword = nil;
            }
            [kdbEntry updateWithParent:parentGroup withTitle:neuName withIcon:iconId withUsername:neuUsername withPassword:setPassword withUrl:neuUrl withNotes:neuNotes withExpires:neuExpireDate];
        } else {
            kdbEntry = [[KdbEntry alloc] initWithParent:parentGroup withTitle:neuName withIcon:iconId withUsername:neuUsername withPassword:neuPassword withUrl:neuUrl withNotes:neuNotes withExpires:neuExpireDate forDatabase:parentGroup.database];
        }
        
        self.loadingMessage = @"Saving";
        [self networkRequestStarted];
        
        kdbEntry.database.savingDelegate = self;
        [kdbEntry.database save];
    }
}

- (void)databaseSaveComplete:(id<Database>)database {
    [self networkRequestStopped];
    [masterView reloadSection:1];
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
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section){
        case 1:
            return 2;
            break;
        case 3:
            return 3;
            break;
        case 0:
        case 2:
        case 4:
        case 5:
        case 6:
            return 1;
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section){
        case 0:
            return @"Parent Group";
            break;
        case 1:
            return @"Entry Name";
            break;
        case 2:
            return @"Username";
            break;
        case 3:
            return @"Password";
            break;
        case 4:
            return @"URL";
            break;
        case 5:
            return @"Notes";
            break;
        case 6:
            return @"Expires";
            break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *NoteCellIdentifier = @"NoteCell";
    NSString *TextCellIdentifier = [@"TextCell" stringByAppendingFormat:@"%d%d", indexPath.section, indexPath.row];
    
	UITableViewCell *cell;
    UITextField *field;
    UITextView *notes;
    NSDateComponents *comps;
    
    if(indexPath.section == 0 || (indexPath.section == 1 && indexPath.row == 1) || (indexPath.section == 3 && indexPath.row == 2)){ // disclosure cells
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
                [cell.imageView setImage:nil];
                cell.textLabel.text = @"Choose Icon";
                break;
            case 3:
                [cell.imageView setImage:nil];
                cell.textLabel.text = @"Generate Password";
                break;
        }
        
    } else if(indexPath.section == 5) { // notes cell
        cell = [tableView dequeueReusableCellWithIdentifier:NoteCellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoteCellIdentifier] autorelease];
            notes = [[UITextView alloc] initWithFrame:CGRectMake(2, 2, cell.contentView.frame.size.width - 4, cell.contentView.frame.size.height - 4)];
            notes.backgroundColor = [UIColor clearColor];
            notes.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            notes.font = [UIFont systemFontOfSize:17];
            notes.delegate = self;
            notes.tag = 50;
            [cell.contentView addSubview:notes];
            [notes release];
        }
        notes = (UITextView*)[cell viewWithTag:50];
        notes.text = neuNotes;
    } else { // text cells
        cell = [tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextCellIdentifier] autorelease];
            //field = [[UITextField alloc] initWithFrame:CGRectMake(21, 12, 282, 26)];
            //[cell addSubview:field];
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

        if(field != nil){
            if(indexPath.section == 5){
                field.returnKeyType = UIReturnKeyDefault;
            } else {
                field.returnKeyType = UIReturnKeyDone;
            }
            if(indexPath.section == 6){
                field.clearButtonMode = UITextFieldViewModeAlways;
            } else {
                field.clearButtonMode = UITextFieldViewModeWhileEditing;
            }
            if(indexPath.section == 4){
                field.keyboardType = UIKeyboardTypeURL;
                field.autocapitalizationType = UITextAutocapitalizationTypeNone;
            } else if(indexPath.section == 2){
                field.keyboardType = UIKeyboardTypeEmailAddress;
                field.autocapitalizationType = UITextAutocapitalizationTypeNone;
            } else {
                field.keyboardType = UIKeyboardTypeDefault;
                field.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
            if(indexPath.section == 3){
                field.secureTextEntry = YES;
            } else {
                field.secureTextEntry = NO;
            }
            if(indexPath.section == 1 && indexPath.row == 0){
                [cell.imageView setImage:neuIcon];
                int offset;
                if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
                    ([UIScreen mainScreen].scale == 2.0)) {
                    offset = 47;
                } else {
                    offset = 36;
                }
                [field setFrame:CGRectMake(offset, 0, cell.contentView.frame.size.width - offset, cell.contentView.frame.size.height)];
            } else {
                [cell.imageView setImage:nil];
            }
            
            switch(indexPath.section){
                case 1:
                    field.text = neuName;
                    field.placeholder = @"Required";
                    break;
                case 2:
                    field.text = neuUsername;
                    field.placeholder = @"None";
                    break;
                case 3:
                    if(indexPath.row == 0){
                        field.text = neuPassword;
                        field.placeholder = @"New Password";
                    } else {
                        field.text = verifyPassword;
                        field.placeholder = @"Verify Password";
                    }
                    break;
                case 4:
                    field.text = neuUrl;
                    field.placeholder = @"None";
                    break;
                case 6:
                    comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:neuExpireDate];
                    if([comps year] == 2999){
                        field.text = @"";
                    } else {
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setTimeStyle:NSDateFormatterShortStyle];
                        [formatter setDateStyle:NSDateFormatterMediumStyle];
                        field.text = [formatter stringFromDate:neuExpireDate];
                        [formatter release];
                    }
                    field.placeholder = @"Never";
                    field.inputView = datePicker;
                    field.inputAccessoryView = dateBar;
                    
                    break;
            }
            
            field.font = [UIFont boldSystemFontOfSize:17];
            field.tag = (indexPath.section * 10) + indexPath.row;
            field.adjustsFontSizeToFitWidth = YES;
            field.delegate = self;
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 5){ // need modified height for notes cell
		return UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 151 : 62;
	}
	return 44;
}

#pragma mark -
#pragma mark tableviewdelegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:1];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.scrollToPath = indexPath;
    if(indexPath.section == 0){
        [self hideKeyboard];
        ParentGroupPicker *pgp = [[ParentGroupPicker alloc] initWithNibName:@"KdbGroupViewController" bundle:nil];
        pgp.title = @"Select Parent";
        pgp.kdbGroup = [parentGroup.database rootGroup];
        pgp.delegate = self;
        pgp.showNone = NO;
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
        
    } else if(indexPath.section == 3 && indexPath.row == 2){
        [self hideKeyboard];
        GeneratePasswordViewController *gpvc = [[GeneratePasswordViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
        gpvc.delegate = self;
        //UINavigationController *navBar = [[UINavigationController alloc] initWithRootViewController:gpvc];
        [self.navigationController pushViewController:gpvc animated:YES];
        [gpvc release];
        //[navBar release];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - TextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.scrollToPath = nil; //[NSIndexPath indexPathForRow:0 inSection:5];
    currentFirstResponder = 50;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.neuNotes = textView.text;
    currentFirstResponder = 0;
}

#pragma mark -
#pragma mark TextField delegate

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if(textField.tag == 60){
        self.neuExpireDate = [self neverExpires];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:6]] withRowAnimation:UITableViewRowAnimationNone];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self hideKeyboard];
	return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if(textField.tag == 60){
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:neuExpireDate];
        if([comps year] == 2999){
            [datePicker setDate:[NSDate date] animated:NO];
        } else {
            [datePicker setDate:neuExpireDate animated:NO];
        }
    }
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.scrollToPath = [NSIndexPath indexPathForRow:0 inSection:textField.tag / 10];
    currentFirstResponder = textField.tag;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch(textField.tag){
        case 10:
            self.neuName = textField.text;
            break;
        case 20:
            self.neuUsername = textField.text;
            break;
        case 30:
            self.neuPassword = textField.text;
            break;
        case 31:
            self.verifyPassword = textField.text;
            break;
        case 40:
            self.neuUrl = textField.text;
            break;
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
    [kdbEntry release];
    [neuIcon release];
    [datePicker release];
    [dateBar release];
    [iconPop release];
    [scrollToPath release];
    //[datePickerView release];
    [super dealloc];
}


@end