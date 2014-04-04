//
//  KdbEntryViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KdbEntry.h"
#import "LoadingView.h"


@interface KdbEntryViewController : UIViewController<UIActionSheetDelegate> {
	KdbEntry *kdbEntry;
	BOOL revealSecret;
}

@property (retain, nonatomic) KdbEntry *kdbEntry;
@property (nonatomic) BOOL revealSecret;

- (UITableView*) tableView;
- (void)revealButtonClicked;

@end
