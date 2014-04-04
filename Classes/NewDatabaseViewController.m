//
//  NewDatabaseViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 9/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NewDatabaseViewController.h"

@implementation NewDatabaseViewController

@synthesize restClient;
@synthesize dbName;
@synthesize password;
@synthesize verifyPassword;
@synthesize location;
@synthesize currentFirstResponder;
@synthesize delegate;
@synthesize scrollToPath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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

#pragma mark - Actions

- (void)hideKeyboard {
    UIView *fld = [self.view viewWithTag:currentFirstResponder];
    [fld resignFirstResponder];
}

- (void)saveButtonClicked {
    [self hideKeyboard];
    if(dbName == nil || dbName.length == 0){
        UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must enter a file name." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [error show];
        [error release];
        return;
    }
    
    if([dbName rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_ "] invertedSet]].location != NSNotFound){
        UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The file name contains illegal characters. Please use only alphanumerics, spaces, dashes, or underscores." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [error show];
        [error release];
        return;
    }
    
    if(password == nil){
        UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must enter a password." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [error show];
        [error release];
        return;
    }
    
    if(![password isEqualToString:verifyPassword]){
        UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The passwords you entered did not match." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [error show];
        [error release];
        return;
    }
    
    self.loadingMessage = @"Creating";
    [self networkRequestStarted];
    [restClient loadMetadata:[location stringByAppendingPathComponent:[dbName stringByAppendingPathExtension:@"kdb"]]];
}

- (void)alertError:(NSError*)error {
	NSString *msg = @"DropBox reported an unknown error.";
	if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
		msg = [[error userInfo] objectForKey:@"error"];
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DropBox Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)uploadTemplate {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"kdb"];
    KdbReader *reader = [[KdbReader alloc] initWithKdbFile:path usingPassword:@"password"];
    if(reader.hasError){
        [self networkRequestStopped];
        UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was a fatal error loading the database template. You may need to reinstall PassDrop." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [error show];
        [error release];
    } else {
        NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[dbName stringByAppendingPathExtension:@"kdb"]];
        kpass_db *kpdb = [reader kpDatabase];
        KdbWriter *writer = [[KdbWriter alloc] init];
        const char *cPw = [password cStringUsingEncoding:NSUTF8StringEncoding];
        uint8_t *pwH = malloc(sizeof(uint8_t)*32);
        kpass_hash_pw(kpdb, cPw, pwH);
        if(![writer saveDatabase:kpdb withPassword:pwH toFile:tempFile]){
            [self networkRequestStopped];
            UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:writer.lastError delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [error show];
            [error release];
        } else {
            [restClient uploadFile:[dbName stringByAppendingPathExtension:@"kdb"] toPath:self.location withParentRev:nil fromPath:tempFile];
        }
        [writer release];
    }
    [reader release];
}

- (void)cleanup {
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[dbName stringByAppendingPathExtension:@"kdb"]];
    if([fm fileExistsAtPath:tempPath]){
        [fm removeItemAtPath:tempPath error:nil];
    }
    [fm release];
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    self.title = @"New File";
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonClicked)];
	self.navigationItem.rightBarButtonItem = saveButton;
	[saveButton release];
    
    restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
	restClient.delegate = self;
    
    currentFirstResponder = 0;
    
    oldkeyboardHeight = 0;
    keyboardShowing = NO;
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self hideKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - Rest client delegate

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if(!metadata.isDeleted){
        [self networkRequestStopped];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"That file already exists. Please choose a different file name." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        [alert release];
    } else {
        // file was found, but was deleted, we're good to create it
        [self uploadTemplate];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    if(error.code == 404){
        // file not found, means we're good to create it
        [self uploadTemplate];
    } else {
        [self networkRequestStopped];
        [self alertError:error];
    }
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath {
    [self cleanup];
    [self networkRequestStopped];
    [delegate newDatabaseCreated:destPath];
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    [self cleanup];
    [self networkRequestStopped];
    [self alertError:error];
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
            return @"File Name";
        case 1:
            return @"Password";
    }
    return nil;
}

- (NSString *)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0){
        return @"The .kdb extension will be added for you.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
	UITableViewCell *cell;
    UITextField *field;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
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
    
    field.tag = ((indexPath.section + 1) * 10) + indexPath.row;
    
    field.font = [UIFont boldSystemFontOfSize:17];
    
    field.adjustsFontSizeToFitWidth = YES;
    if(indexPath.section == 0){
        field.text = dbName;
        field.placeholder = @"Required";
    } else {
        field.secureTextEntry = YES;
        if(indexPath.row == 0){
            field.text = password;
            field.placeholder = @"Password";
        } else {
            field.text = verifyPassword;
            field.placeholder = @"Verify Password";
        }
    }
    field.returnKeyType = UIReturnKeyDone;
    field.keyboardType = UIKeyboardTypeDefault;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.delegate = self;
  
    return cell;
}

#pragma mark -
#pragma mark tableviewdelegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:1];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self.view viewWithTag:(indexPath.section + 1) * 10 + indexPath.row] becomeFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self hideKeyboard];
	return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.scrollToPath = [NSIndexPath indexPathForRow:textField.tag % 10 inSection:(textField.tag / 10)-1];
    currentFirstResponder = textField.tag;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch(textField.tag){
        case 10:
            self.dbName = textField.text;
            break;
        case 20:
            self.password = textField.text;
            break;
        case 21:
            self.verifyPassword = textField.text;
            break;
    }
    
    currentFirstResponder = 0;
}

#pragma mark - memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [dbName release];
    [password release];
    [verifyPassword release];
    [restClient release];
    [delegate release];
    [location release];
    [super dealloc];
}

@end
