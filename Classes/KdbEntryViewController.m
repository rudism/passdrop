//
//  KdbEntryViewController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KdbEntryViewController.h"

@implementation KdbEntryViewController

@synthesize kdbEntry;
@synthesize revealSecret;

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
	UIBarButtonItem *revealButton = [[UIBarButtonItem alloc] initWithTitle:@"Reveal" style:UIBarButtonItemStyleBordered target:self action:@selector(revealButtonClicked)];
	self.navigationItem.rightBarButtonItem = revealButton;
	[revealButton release];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [self.navigationItem setHidesBackButton:YES animated:NO];
    }
    self.view.autoresizesSubviews = YES;
}

- (void)revealButtonClicked {
	if(self.revealSecret){
		self.navigationItem.rightBarButtonItem.title = @"Reveal";
		self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleBordered;
	} else {
		self.navigationItem.rightBarButtonItem.title = @"Hide";
		self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
	}
	self.revealSecret = !self.revealSecret;
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0], nil] withRowAnimation:UITableViewRowAnimationNone];
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

- (void)viewDidAppear:(BOOL)animated {
    if([self.navigationItem.rightBarButtonItem.title isEqual: @"Hide"]){
        self.revealSecret = YES;
    } else {
        self.revealSecret = NO;
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark -
#pragma mark actionsheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1){
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = kdbEntry.entryUrl;
        
        LoadingView *dlv = [[LoadingView alloc] initWithTitle:@"Copied"];
		[dlv setImage:[UIImage imageNamed:@"clipboard.png"]];
		[dlv show];
		[dlv dismissAnimated:YES];
		[dlv release];
    } else if(buttonIndex == 0) {
        NSURL *url = [NSURL URLWithString:kdbEntry.entryUrl];
        if(url == nil){
            UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Invalid Url" message:@"That doesn't appear to be a valid URL." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [error show];
            [error release];
        } else {
            BOOL opened = [[UIApplication sharedApplication] openURL:url];
            if(!opened){
                NSRange protocolRange = [kdbEntry.entryUrl rangeOfString:@"/"];
                NSRange netpathRange = [kdbEntry.entryUrl rangeOfString:@"\\"];
                if(protocolRange.location == NSNotFound && netpathRange.location == NSNotFound){
                    url = [NSURL URLWithString:[@"http://" stringByAppendingString:kdbEntry.entryUrl]];
                    opened = [[UIApplication sharedApplication] openURL:url];
                }
            }
            if(!opened){
                UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Invalid Url" message:@"There are no installed apps that can open that URL." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [error show];
                [error release];

            }
        }
    }
}

#pragma mark -
#pragma mark tableview delegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:1];
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath section] == 2 || ([indexPath section] == 1 && [kdbEntry.entryNotes length] == 0)){
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 0 && [indexPath row] == 2){ // url needs action sheet
		UIActionSheet *urlSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Launch URL", @"Copy to Clipboard", nil];
		//[urlSheet showInView:self.view];
        [urlSheet showFromRect:[tableView cellForRowAtIndexPath:indexPath].frame inView:self.view animated:YES];
		[urlSheet release];
	} else {
		// copy cell content to clipboard
		UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
		
		switch([indexPath section]){
			case 0:
				switch([indexPath row]){
					case 0:
						pasteboard.string = kdbEntry.entryUsername;
						break;
					case 1:
						pasteboard.string = kdbEntry.entryPassword;
						break;
				}
				break;
			case 1:
				pasteboard.string = cell.textLabel.text;
				break;
		}
		
		LoadingView *dlv = [[LoadingView alloc] initWithTitle:@"Copied"];
		[dlv setImage:[UIImage imageNamed:@"clipboard.png"]];
		[dlv show];
		[dlv dismissAnimated:YES];
		[dlv release];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([kdbEntry.entryNotes length] > 0){
        return 3;
    } else {
        return 2;
    }
	// todo, add 1 for attachment if necessary, add 1 for expiration date if necessary
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section){
		case 0:
            if([kdbEntry.entryUrl length] > 0){
                return 3; // username, password, url
            } else {
                return 2;
            }
			break;
		case 1:
            if([kdbEntry.entryNotes length] > 0){
                return 1; // comments
            } else {
                return 4;
            }
			break;
		case 2:
			return 4; // dates
			break;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch(section){
		case 0:
			return [kdbEntry entryName];
			break;
		case 1:
            if([kdbEntry.entryNotes length] > 0){
                return @"Notes";
            } else {
                return @"Dates";
            }
			break;
		case 2:
			return @"Dates";
			break;
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *InfoCellIdentifier = @"InfoCell";
	static NSString *NoteCellIdentifier = @"NoteCell";
    static NSString *DateCellIdentifier = @"DateCell";
	
	UITableViewCell *cell;
	
	if([indexPath section] == 1 && [kdbEntry.entryNotes length] > 0){ // notes
		cell = [tableView dequeueReusableCellWithIdentifier:NoteCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoteCellIdentifier] autorelease];
		}
		
        cell.textLabel.font = [UIFont systemFontOfSize:17];
		cell.textLabel.text = kdbEntry.entryNotes;
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
	} else if ([indexPath section] == 0) { // password, login, url
		cell = [tableView dequeueReusableCellWithIdentifier:InfoCellIdentifier];
		if(cell == nil){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:InfoCellIdentifier] autorelease];
		}

        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:17];
        switch([indexPath row]){
            case 0: // username
                cell.textLabel.text = @"Username";
                if(self.revealSecret){
                    cell.detailTextLabel.text = kdbEntry.entryUsername.length > 0 ? kdbEntry.entryUsername : @" ";
                } else {
                    cell.detailTextLabel.text = @"⁕⁕⁕⁕⁕⁕⁕⁕";
                }
                cell.detailTextLabel.textColor = [UIColor blackColor];
                break;
            case 1: // password
                cell.textLabel.text = @"Password";
                if(self.revealSecret){
                    cell.detailTextLabel.text = kdbEntry.entryPassword.length > 0 ? kdbEntry.entryPassword : @" ";
                } else {
                    cell.detailTextLabel.text = @"⁕⁕⁕⁕⁕⁕⁕⁕";
                }
                cell.detailTextLabel.textColor = [UIColor blackColor];
                break;
            case 2: // url
                cell.textLabel.text = @"URL";
                cell.detailTextLabel.text = kdbEntry.entryUrl;
                cell.detailTextLabel.textColor = [UIColor blueColor];
                break;
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:DateCellIdentifier];
		if(cell == nil){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DateCellIdentifier] autorelease];
		}
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        
        /*cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:17];*/
        
        switch([indexPath row]){
            case 0: // created
                cell.textLabel.text = @"Created";
                cell.detailTextLabel.text = [formatter stringFromDate:[kdbEntry createdDate]];
                break;
            case 1: // accessed
                cell.textLabel.text = @"Accessed";
                cell.detailTextLabel.text = [formatter stringFromDate:[kdbEntry accessDate]];
                break;
            case 2: // modified
                cell.textLabel.text = @"Modified";
                cell.detailTextLabel.text = [formatter stringFromDate:[kdbEntry modifiedDate]];
                break;
            case 3: // expires
                cell.textLabel.text = @"Expires";
                NSDate *edate = [kdbEntry expireDate];
                NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:edate];
                if([comps year] == 2999){
                    cell.detailTextLabel.text = @"Never";
                } else {
                    cell.detailTextLabel.text = [formatter stringFromDate:edate];
                }
                break;
        }
        
        [formatter release];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 1 && [indexPath row] == 0 && [kdbEntry.entryNotes length] > 0){ // need modified height for notes cell
		CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - 50;
		CGFloat maxHeight = 9999;
		CGSize maximumLabelSize = CGSizeMake(maxWidth,maxHeight);
		
		CGSize expectedLabelSize = [kdbEntry.entryNotes sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeWordWrap];
		return expectedLabelSize.height + 13;
	}
	return 44;
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
    [super dealloc];
}


@end
