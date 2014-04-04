//
//  EditGroupViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define NO_ICON_SET 9999

#import <UIKit/UIKit.h>
#import "KdbGroup.h"
#import "DatabaseManager.h"
#import "ParentGroupPicker.h"
#import "IconPicker.h"
#import "NetworkActivityViewController.h"
#import "PassDropAppDelegate.h"
#import "KdbGroupViewController.h"

@class KdbGroupViewController;

@interface EditGroupViewController : NetworkActivityViewController<ParentGroupPickerDelegate, UITextFieldDelegate, IconPickerDelegate, DatabaseDelegate> {
    KdbGroup *kdbGroup;
    KdbGroup *parentGroup;
    UIImage *neuIcon;
    uint32_t newIconId;
    NSString *neuName;
    BOOL editMode;
    int currentFirstResponder;
    KdbGroupViewController *masterView;
    UIPopoverController *iconPop;
    int oldkeyboardHeight;
    BOOL keyboardShowing;
}

@property (retain, nonatomic) KdbGroup *kdbGroup;
@property (nonatomic) BOOL editMode;
@property (retain, nonatomic) KdbGroup *parentGroup;
@property (retain, nonatomic) UIImage *neuIcon;
@property (nonatomic) uint32_t newIconId;
@property (copy, nonatomic) NSString *neuName;
@property (retain, nonatomic) KdbGroupViewController *masterView;
@property (retain, nonatomic) UIPopoverController *iconPop;

- (UITableView*) tableView;
- (void)hideKeyboard;

@end
