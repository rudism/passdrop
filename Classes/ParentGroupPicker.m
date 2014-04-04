//
//  ParentGroupPicker.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 7/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ParentGroupPicker.h"


@implementation ParentGroupPicker

@synthesize kdbGroup;
@synthesize searchResults;
@synthesize savedSearchTerm;
@synthesize delegate;
@synthesize showNone;

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
     [super viewDidLoad];
     if([kdbGroup isRoot]){
         UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSelection)];
         self.navigationItem.leftBarButtonItem = backButton;
         [backButton release];
         
         if(showNone){
             UIBarButtonItem *noneButton = [[UIBarButtonItem alloc] initWithTitle:@"None" style:UIBarButtonItemStyleBordered target:self action:@selector(setAsRoot)];
             self.navigationItem.rightBarButtonItem = noneButton;
             [noneButton release];
         }
     }
     self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
     self.tableView.alwaysBounceVertical = YES;
 
     if ([self savedSearchTerm])
     {
         [[[self searchDisplayController] searchBar] setText:[self savedSearchTerm]];
     }
 }
 

/*- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate{
    return YES;
}

#pragma mark - actions

- (void)cancelSelection {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setAsRoot {
    [delegate parentGroupSelected:kdbGroup];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - tableview delegate

- (UITableView*) tableView {
	return (UITableView*)[self.view viewWithTag:1];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [delegate parentGroupSelected:[kdbGroup.subGroups objectAtIndex:indexPath.row]];
    [self.navigationController popToViewController:[delegate viewController] animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	KdbGroup *cellGroup = [kdbGroup.subGroups objectAtIndex:[indexPath row]];
    ParentGroupPicker *pgp = [[ParentGroupPicker alloc] initWithNibName:@"KdbGroupViewController" bundle:nil];
    pgp.title = [cellGroup groupName];
    pgp.delegate = self.delegate;
    pgp.kdbGroup = cellGroup;
    [self.navigationController pushViewController:pgp animated:YES];
    [pgp release];
}

#pragma mark - tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == [[self searchDisplayController] searchResultsTableView]){
        if(self.searchResults){
            return [self.searchResults count];
        }
        return 0;
    } else {
        return [kdbGroup.subGroups count];
    }
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    KdbGroup *cellGroup;
    
    if(tableView != [[self searchDisplayController] searchResultsTableView]){
        cellGroup = [kdbGroup.subGroups objectAtIndex:[indexPath row]];
        if([[cellGroup subGroups] count] > 0 && ([delegate childGroup] == nil || cellGroup != [delegate childGroup])){
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        cellGroup = [self.searchResults objectAtIndex:[indexPath row]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if([delegate childGroup] != nil && cellGroup == [delegate childGroup]){
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.userInteractionEnabled = NO;
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.userInteractionEnabled = YES;
    }
	
    cell.textLabel.text = [cellGroup groupName];
    [cell.imageView setImage:[cellGroup groupIcon]];
	
	return cell;
}

#pragma mark - search stuff

- (BOOL)kdbGroup:(KdbGroup*)group isMatchForTerm:(NSString*)searchTerm {
    if([[[group groupName] lowercaseString] rangeOfString:[searchTerm lowercaseString]].location != NSNotFound){
        return YES;
    }
    return NO;
}

-(NSArray*)getMatchingGroupsFromGroup:(KdbGroup*)group forSearchTerm:(NSString*)searchTerm {
    NSMutableArray *matches = [[[NSMutableArray alloc] init] autorelease];
    
    for(int i = 0; i < [group.subGroups count]; i++){
        if([self kdbGroup:[group.subGroups objectAtIndex:i] isMatchForTerm:searchTerm] && ![matches containsObject:[group.subGroups objectAtIndex:i]]){
            [matches addObject:[group.subGroups objectAtIndex:i]];
        }
    }
    for(int i = 0; i < [group.subGroups count]; i++){
        [matches addObjectsFromArray:[self getMatchingGroupsFromGroup:[group.subGroups objectAtIndex:i] forSearchTerm:searchTerm]];
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
    [self.searchResults addObjectsFromArray:[self getMatchingGroupsFromGroup:kdbGroup forSearchTerm:searchString]];
    
    return YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [savedSearchTerm release];
    savedSearchTerm = nil;
    [self.tableView reloadData];
}

#pragma mark - memory management

- (void)dealloc
{
    self.searchDisplayController.delegate = nil;
    self.searchDisplayController.searchResultsDelegate = nil;
    self.searchDisplayController.searchResultsDataSource = nil;
    [super dealloc];
}

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

/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}*/

@end
