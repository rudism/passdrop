//
//  GeneratePasswordViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 9/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GeneratePasswordViewController.h"

@implementation GeneratePasswordViewController

@synthesize password;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
    self.title = @"Generate";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPassword)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Use" style:UIBarButtonItemStyleDone target:self action:@selector(usePassword)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
    
    currentFirstResponder = 0;
    app = (PassDropAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    pwUpper = app.prefs.pwUpper;
    pwLower = app.prefs.pwLower;
    pwNumbers = app.prefs.pwNumbers;
    pwSpaces = app.prefs.pwSpaces;
    pwMinus = app.prefs.pwMinus;
    pwUnderline = app.prefs.pwUnderline;
    pwSpecials = app.prefs.pwSpecials;
    pwExcludes = app.prefs.pwExcludes;
    pwDiversity = app.prefs.pwDiversity;
    pwReveal = app.prefs.pwReveal;
    pwLength = app.prefs.pwLength;
    pwBrackets = app.prefs.pwBrackets;
    pwPunctuation = app.prefs.pwPunctuation;

    srand(time(NULL));
    
    oldkeyboardHeight = 0;
    keyboardShowing = NO;
    
    [super viewDidLoad];
}

// hack to fix weird bug with the leftbarbuttonitems disappearing
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        UIBarButtonItem *sb = self.navigationItem.leftBarButtonItem;
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:sb.title style:sb.style target:sb.target action:sb.action] autorelease];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard) name:UIApplicationWillResignActiveNotification object:nil];
    [self generatePassword];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self hideKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
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

- (void)hideKeyboard {
    UIView *fld = [self.view viewWithTag:currentFirstResponder];
    [fld resignFirstResponder];
}

- (void)cancelPassword {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)usePassword {
    [delegate passwordGenerated:password];
    
    app.prefs.pwUpper = pwUpper;
    app.prefs.pwLower = pwLower;
    app.prefs.pwNumbers = pwNumbers;
    app.prefs.pwSpaces = pwSpaces;
    app.prefs.pwMinus = pwMinus;
    app.prefs.pwUnderline = pwUnderline;
    app.prefs.pwSpecials = pwSpecials;
    app.prefs.pwExcludes = pwExcludes;
    app.prefs.pwDiversity = pwDiversity;
    app.prefs.pwReveal = pwReveal;
    app.prefs.pwLength = pwLength;
    app.prefs.pwBrackets = pwBrackets;
    app.prefs.pwPunctuation = pwPunctuation;
    
    [app.prefs savePrefs];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) generatePassword {
    static NSString *pwaLower = @"abcdefghijklmnopqrstuvwxyz";
    static NSString *pwaUpper = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    static NSString *pwaLowerEx = @"abcdefghijkmnopqrstuvwxyz";
    static NSString *pwaUpperEx = @"ABCDEFGHJKMNPQRSTUVWXYZ";
    static NSString *pwaNumber = @"0123456789";
    static NSString *pwaNumberEx = @"23456789";
    static NSString *pwaSpecial = @"!@#$%^&*";
    static NSString *pwaBrackets = @"()[]{}<>";
    static NSString *pwaPunctuation = @".,:;/\\?'\"";
    
    NSMutableString *characters = [[NSMutableString alloc] initWithString:@""];
    if(pwExcludes){
        if(pwUpper) [characters appendString:pwaUpperEx];
        if(pwLower) [characters appendString:pwaLowerEx];
        if(pwNumbers) [characters appendString:pwaNumberEx];
    } else {
        if(pwUpper) [characters appendString:pwaUpper];
        if(pwLower) [characters appendString:pwaLower];
        if(pwNumbers) [characters appendString:pwaNumber];
    }
    if(pwSpaces) [characters appendString:@" "];
    if(pwMinus) [characters appendString:@"-"];
    if(pwUnderline) [characters appendString:@"_"];
    if(pwSpecials) [characters appendString:pwaSpecial];
    if(pwBrackets) [characters appendString:pwaBrackets];
    if(pwPunctuation) [characters appendString:pwaPunctuation];
    
    NSMutableString *newPassword = [[NSMutableString alloc] initWithCapacity:pwLength];
    for(int i = 0; i < pwLength; i++){
        if([characters length] > 0){
            [newPassword appendFormat:@"%c", [characters characterAtIndex:rand()%[characters length]]];
        } else {
            [newPassword setString:@""];
            break;
        }
    }
    
    if(pwDiversity){
        int idx[5];
        int idxlen = 0;
        if(pwUpper) idx[idxlen++] = 0;
        if(pwLower) idx[idxlen++] = 1;
        if(pwNumbers) idx[idxlen++] = 2;
        if(pwSpecials) idx[idxlen++] = 3;
        if(pwSpaces || pwMinus || pwUnderline || pwBrackets || pwPunctuation) idx[idxlen++] = 4;
        
        for(int i = 0; i < idxlen; i++){
            int dest = rand()%idxlen;
            int temp = idx[dest];
            idx[dest] = idx[i];
            idx[i] = temp;
        }
        
        // add at least 1 char from lower, upper, numbers, specials, and the rest if they are enabled
        for(int i = 0; i < pwLength; i++){
            if(i >= idxlen) break;
            
            NSRange range = NSMakeRange(i, 1);
            
            switch(idx[i]){
                case 0:
                    if(pwExcludes){
                        [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [pwaUpperEx characterAtIndex:rand()%[pwaUpperEx length]]]];
                    } else {
                        [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [pwaUpper characterAtIndex:rand()%[pwaUpper length]]]];
                    }
                    break;
                case 1:
                    if(pwExcludes){
                        [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [pwaLowerEx characterAtIndex:rand()%[pwaLowerEx length]]]];
                    } else {
                        [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [pwaLower characterAtIndex:rand()%[pwaLower length]]]];
                    }
                    break;
                case 2:
                    if(pwExcludes){
                        [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [pwaNumberEx characterAtIndex:rand()%[pwaNumberEx length]]]];
                    } else {
                        [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [pwaNumber characterAtIndex:rand()%[pwaNumber length]]]];
                    }
                    break;
                case 3:
                    [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [pwaSpecial characterAtIndex:rand()%[pwaSpecial length]]]];
                    break;
                case 4:
                    [characters setString:@""];
                    if(pwSpaces) [characters appendString:@" "];
                    if(pwMinus) [characters appendString:@"-"];
                    if(pwUnderline) [characters appendString:@"_"];
                    if(pwBrackets) [characters appendString:pwaBrackets];
                    if(pwPunctuation) [characters appendString:pwaPunctuation];
                    if([characters length] > 0)
                        [newPassword replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%c", [characters characterAtIndex:rand()%[characters length]]]];
                    break;
            }
        }
        
        // distribute the new characters randomly in the string
        if([newPassword length] > 0){
            for(int i = 0; i < pwLength; i++){
                if(i > idxlen) break;
                int dest = rand()%[newPassword length];
                if(i != dest){
                    unichar destchar = [newPassword characterAtIndex:dest];
                    unichar srcchar = [newPassword characterAtIndex:i];

                    [newPassword replaceCharactersInRange:NSMakeRange(dest, 1) withString:[NSString stringWithCharacters:&srcchar length:1]];
                    [newPassword replaceCharactersInRange:NSMakeRange(i, 1) withString:[NSString stringWithCharacters:&destchar length:1]];
                }
            }
        }
    }
    
    self.password = newPassword;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [characters release];
    [newPassword release];
}

- (void)switchToggled:(id)sender {
    [self hideKeyboard];
    UISwitch *button = (UISwitch*)sender;
    switch(button.tag){
        case 10:
            pwUpper = button.isOn;
            break;
        case 11:
            pwLower = button.isOn;
            break;
        case 12:
            pwNumbers = button.isOn;
            break;
        case 13:
            pwSpaces = button.isOn;
            break;
        case 14:
            pwMinus = button.isOn;
            break;
        case 15:
            pwUnderline = button.isOn;
            break;
        case 16:
            pwSpecials = button.isOn;
            break;
        case 17:
            pwBrackets = button.isOn;
            break;
        case 18:
            pwPunctuation = button.isOn;
            break;
        case 20:
            pwExcludes = button.isOn;
            break;
        case 21:
            pwDiversity = button.isOn;
            break;
        case 22:
            pwReveal = button.isOn;
            break;
    }
    [self generatePassword];
}


#pragma mark -
#pragma mark tableviewdatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section){
        case 1:
            return 9;
            break;
        case 2:
            return 4;
            break;
        case 0:
            return 2;
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section){
        case 1:
            return @"Include Characters";
            break;
        case 2:
            return @"Options";
            break;
        case 0:
            return @"Password";
            break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *LengthCellIdentifier = @"LengthCell";
    static NSString *PasswordCellIdentifier = @"PasswordCell";
    static NSString *ButtonCellIdentifier = @"ButtonCell";
    
    UITableViewCell *cell;
    UISwitch *button;
    UITextField *field;
    
    if(indexPath.section == 1 || (indexPath.section == 2 && indexPath.row < 3)){ // check mark rows
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            button = [[UISwitch alloc] initWithFrame:CGRectMake(0,0,0,0)];
            [button addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = button;
            [button release];
        }
        button = (UISwitch*)cell.accessoryView;
        button.tag = (indexPath.section * 10) + indexPath.row;
        switch(indexPath.section){
            case 1:
                switch(indexPath.row){
                    case 0:
                        cell.textLabel.text = @"Uppercase Letters";
                        [button setOn:pwUpper];
                        break;
                    case 1:
                        cell.textLabel.text = @"Lowercase Letters";
                        [button setOn:pwLower];
                        break;
                    case 2:
                        cell.textLabel.text = @"Numbers";
                        [button setOn:pwNumbers];
                        break;
                    case 3:
                        cell.textLabel.text = @"Spaces";
                        [button setOn:pwSpaces];
                        break;
                    case 4:
                        cell.textLabel.text = @"Minus Sign";
                        [button setOn:pwMinus];
                        break;
                    case 5:
                        cell.textLabel.text = @"Underscore";
                        [button setOn:pwUnderline];
                        break;
                    case 6:
                        cell.textLabel.text = @"Special Characters";
                        [button setOn:pwSpecials];
                        break;
                    case 7:
                        cell.textLabel.text = @"Brackets";
                        [button setOn:pwBrackets];
                        break;
                    case 8:
                        cell.textLabel.text = @"Punctuation";
                        [button setOn:pwPunctuation];
                        break;
                }
                break;
            case 2:
                switch(indexPath.row){
                    case 0:
                        cell.textLabel.text = @"Exclude Look-alikes";
                        [button setOn:pwExcludes];
                        break;
                    case 1:
                        cell.textLabel.text = @"Force Diversity";
                        [button setOn:pwDiversity];
                        break;
                    case 2:
                        cell.textLabel.text = @"Reveal Password";
                        [button setOn:pwReveal];
                        break;
                }
                break;
        }
    } else if(indexPath.section == 2 && indexPath.row == 3){ // length row
        cell = [tableView dequeueReusableCellWithIdentifier:LengthCellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LengthCellIdentifier] autorelease];
            field = [[UITextField alloc] initWithFrame:CGRectMake(151, 12, 152, 26)];
            field.tag = 13;
            cell.accessoryView = field;
            [field release];
        }
        cell.textLabel.text = @"Length";
        field = (UITextField*)cell.accessoryView;
        
        field.font = [UIFont boldSystemFontOfSize:17];
        field.textAlignment = UITextAlignmentRight;
        field.adjustsFontSizeToFitWidth = NO;
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.returnKeyType = UIReturnKeyDone;
        field.clearButtonMode = UITextFieldViewModeNever;
        field.delegate = self;
        
        field.text = [NSString stringWithFormat:@"%d", pwLength];
        
    } else if(indexPath.section == 0 && indexPath.row == 0){ // password field
        cell = [tableView dequeueReusableCellWithIdentifier:PasswordCellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PasswordCellIdentifier] autorelease];
        }
        if(pwReveal){
            cell.textLabel.text = password;
        } else {
            cell.textLabel.text = @"⁕⁕⁕⁕⁕⁕⁕⁕";
        }
    } else { // generate button
        cell = [tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
        if(cell == nil){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ButtonCellIdentifier] autorelease];
        }
        cell.textLabel.text = @"Generate New";
    }
    
    return cell;
}

#pragma mark -
#pragma mark tableviewdelegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:1];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section){
        case 1:
            return nil;
            break;
        case 2:
            if(indexPath.row < 3){
                return nil;
            } else {
                [(UITextField*)[self.tableView cellForRowAtIndexPath:indexPath].accessoryView becomeFirstResponder];
                return nil;
            }
            break;
    }
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0){
        if(indexPath.row == 0){
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = password;
            LoadingView *dlv = [[LoadingView alloc] initWithTitle:@"Copied"];
            [dlv setImage:[UIImage imageNamed:@"clipboard.png"]];
            [dlv show];
            [dlv dismissAnimated:YES];
            [dlv release];
        } else {
            [self generatePassword];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - TextView delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentFirstResponder = textField.tag;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    int newLength;
    switch(textField.tag){
        case 13:
            newLength = [textField.text intValue];
            if(newLength < 1){
                newLength = 1;
            } else if(newLength > 30000){
                newLength = 30000;
            }
            pwLength = newLength;
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:3 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
    
    currentFirstResponder = 0;
    
    [self generatePassword];
}

#pragma mark - memory management

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [password release];
    [delegate release];
    [super dealloc];
}

@end
