//
//  EditDatabaseViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "PassDropAppDelegate.h"
#import "NetworkActivityViewController.h"

@interface EditDatabaseViewController : NetworkActivityViewController<UITextFieldDelegate, DatabaseDelegate, UIActionSheetDelegate> {
	id<Database> database;
	NSString *neuName;
    int currentFirstResponder;
    NSString *oldPassword;
    NSString *neuPassword;
    NSString *verifyPassword;
    int oldkeyboardHeight;
    BOOL keyboardShowing;
    NSIndexPath *scrollToPath;
}

@property (retain, nonatomic) id<Database> database;
@property (copy, nonatomic) NSString *neuName;
@property (copy, nonatomic) NSString *oldPassword;
@property (copy, nonatomic) NSString *neuPassword;
@property (copy, nonatomic) NSString *verifyPassword;
@property (retain, nonatomic) NSIndexPath *scrollToPath;

- (UITableView*) tableView;
- (void) saveButtonClicked;
- (void) showError:(NSString *)message;

@end
