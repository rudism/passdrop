//
//  DropBoxBrowserController.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DropBoxBrowserController.h"

@implementation DropBoxBrowserController

@synthesize restClient;
@synthesize myPath;
@synthesize isLoaded;
@synthesize loadingView;
@synthesize metadataHash;
@synthesize dirContents;
@synthesize dirBrowsers;
@synthesize tempDbId;
@synthesize tempPath;
@synthesize dbManager;

static int networkIndicatorReq;

- (id) initWithPath:(NSString*)path {
	if((self = [super init])){
		self.myPath = [NSString stringWithString:path];
		networkIndicatorReq = 0;
		self.metadataHash = nil;
		self.dirBrowsers = [[[NSMutableDictionary alloc] init] autorelease];
	}
	return self;
}

#pragma mark - Actions

- (void)newButtonClicked {
    NewDatabaseViewController *ndbvc = [[NewDatabaseViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
    ndbvc.location = myPath;
    ndbvc.delegate = self;
    [self.navigationController pushViewController:ndbvc animated:YES];
    [ndbvc release];
}

- (void)newDatabaseCreated:(NSString *)path {
    NSString *localFile = [dbManager getLocalFilenameForDatabase:[dbManager getIdentifierForDatabase:path] forNewFile:YES];
    [self networkRequestStarted];
    self.tempDbId = [NSString stringWithString:path];
    [restClient loadFile:path intoPath:localFile];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
	restClient.delegate = self;
    
    UIBarButtonItem *newButton = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(newButtonClicked)];
	self.navigationItem.rightBarButtonItem = newButton;
	[newButton release];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	if(!isLoaded){
		[self refreshDirectory];
	}
}

/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark -
#pragma mark PullDown implementation

-(void) pullDownToReloadAction {
	[self refreshDirectory];
}

- (void)refreshDirectory {
	[self networkRequestStarted];
	if(metadataHash == nil){
		[restClient loadMetadata:myPath];
	} else {
		[restClient loadMetadata:myPath withHash:metadataHash];
	}
}

#pragma mark -
#pragma mark Error UI

- (void)alertMessage:(NSString*)message withTitle:(NSString*)alertTitle {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if(dirContents == nil)
		return 0;
    return [dirContents count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.textColor = [UIColor blackColor];
    }
    
    DBMetadata *cellData = [dirContents objectAtIndex:[indexPath row]];
	NSString *fileName = [cellData.path lastPathComponent];
	if (cellData.isDirectory) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[[cell imageView] setImage:[UIImage imageNamed:@"folder_icon.png"]];
		cell.userInteractionEnabled = YES;
		cell.textLabel.textColor = [UIColor blackColor];
	} else {
		if([fileName hasSuffix:@".kdb"]){
			[[cell imageView] setImage:[UIImage imageNamed:@"keepass_icon.png"]];
			cell.userInteractionEnabled = YES;
			
			cell.textLabel.textColor = [UIColor blackColor];
		} else {
			[[cell imageView] setImage:[UIImage imageNamed:@"unknown_icon.png"]];
			//cell.userInteractionEnabled = NO;
			cell.textLabel.textColor = [UIColor lightGrayColor];
		}
	}
	cell.textLabel.text = fileName;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


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
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	DBMetadata *cellData = [dirContents objectAtIndex:[indexPath row]];
	if(cellData.isDirectory){
		if([dirBrowsers objectForKey:cellData.path] == nil){
			DropBoxBrowserController *dirBrowser = [[[DropBoxBrowserController alloc] initWithPath:cellData.path] autorelease];
			dirBrowser.dbManager = dbManager;
			dirBrowser.title = [cellData.path lastPathComponent];
			[dirBrowsers setValue:dirBrowser forKey:cellData.path];
		}
		[self.navigationController pushViewController:[dirBrowsers objectForKey:cellData.path] animated:YES];
	} else {
		//if([cellData.path hasSuffix:@".kdb"]){
			if([dbManager databaseExists:[dbManager getIdentifierForDatabase:cellData.path]]){
				[self alertMessage:@"That database has already been added. You cannot add the same database more than once." withTitle:@"Oops!"];
			} else {
				NSString *localFile = [dbManager getLocalFilenameForDatabase:[dbManager getIdentifierForDatabase:cellData.path] forNewFile:YES];
				[self networkRequestStarted];
				self.tempDbId = [NSString stringWithString:cellData.path];
				[restClient loadFile:cellData.path intoPath:localFile];
			}
		//}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark DropBox/RestClient

- (void)setWorking:(BOOL)working {
    self.view.userInteractionEnabled = !working;
	self.navigationController.view.userInteractionEnabled = !working;
	if (working) {
		loadingView = [[LoadingView alloc] initWithTitle:@"Loading"];
		[loadingView show];
	} else {
		[loadingView dismissAnimated:NO];
		[loadingView release];
		loadingView = nil;
	}
}

- (void)networkRequestStarted {
	UIApplication *app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
	if(networkIndicatorReq == 0){
		[self setWorking:YES];
	}
	networkIndicatorReq++;
}

- (void)networkRequestStopped {
	networkIndicatorReq--;
	if(networkIndicatorReq <= 0){
		UIApplication *app = [UIApplication sharedApplication];
		app.networkActivityIndicatorVisible = NO;
		networkIndicatorReq = 0;
		[self setWorking:NO];
		[self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
	}
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath {
	// now that we downloaded the file, we need to get the hash value for it
	self.tempPath = [NSString stringWithString:destPath];
	[restClient loadMetadata:tempDbId];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
	[self networkRequestStopped];
	[self alertError:error];
	self.tempDbId = nil;
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
	[self networkRequestStopped];
	if(metadata.isDirectory){
		// if it was a directory it means we refreshed this view
		isLoaded = YES;
		self.metadataHash = [NSString stringWithString:metadata.hash];
		self.dirContents = [NSArray arrayWithArray:metadata.contents];
		[self.tableView reloadData];
	} else {
		// otherwise it means we justdownloaded a database for the lastmod date
		NSString *dbId = [dbManager getIdentifierForDatabase:tempDbId];
		[dbManager createNewDatabaseNamed:[dbId lastPathComponent] withId:dbId withLocalPath:tempPath lastModified:metadata.lastModifiedDate revision:metadata.revision];
		self.tempDbId = nil;
		self.tempPath = nil;
	}
}
- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path {
	isLoaded = YES;
	[self networkRequestStopped];
}
- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
	isLoaded = NO;
	[self alertError:error];
	self.dirContents = [[[NSArray alloc] initWithObjects:nil] autorelease];
	[self.tableView reloadData];
	[self networkRequestStopped];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)reset {
	for(NSString* key in dirBrowsers){
		[[dirBrowsers objectForKey:key] reset];
		[dirBrowsers removeObjectForKey:key];
	}
	self.dirBrowsers = [[[NSMutableDictionary alloc] init] autorelease];
	isLoaded = NO;
	self.metadataHash = nil;
	self.dirContents = nil;
	[self.tableView reloadData];
}


- (void)dealloc {
	[self reset];
	[dbManager release];
	[dirBrowsers release];
	[dirContents release];
	[myPath release];
	[metadataHash release];
    [super dealloc];
}


@end

