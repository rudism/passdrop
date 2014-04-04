//
//  KdbGroupViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KdbGroup.h"
#import "NetworkActivityViewController.h"
#import "KdbEntryViewController.h"
#import "DatabaseManager.h"
#import "EditGroupViewController.h"
#import "EditEntryViewController.h"

@interface KdbGroupViewController : NetworkActivityViewController<DatabaseDelegate, UITableViewDataSource, UISearchDisplayDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate> {
	KdbGroup *kdbGroup;
    NSMutableArray *searchResults;
    NSString *savedSearchTerm;
    int extraRows;
    int extraSections;
    BOOL isDirty;
}

@property (retain, nonatomic) KdbGroup *kdbGroup;
@property (retain, nonatomic) NSMutableArray *searchResults;
@property (retain, nonatomic) NSString *savedSearchTerm;
@property (nonatomic) int extraRows;
@property (nonatomic) int extraSections;

- (UITableView*) tableView;
- (void)removeLock;
- (BOOL)kdbEntry:(KdbEntry*)entry isMatchForTerm:(NSString*)searchTerm;
- (void)showSyncButton;
- (void)reloadSection:(int)section;
- (void)hideSyncButton;

@end
