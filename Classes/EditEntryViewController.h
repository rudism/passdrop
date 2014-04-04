//
//  EditEntryViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define NO_ICON_SET 9999

#import <UIKit/UIKit.h>
#import "KdbGroup.h"
#import "DatabaseManager.h"
#import "ParentGroupPicker.h"
#import "IconPicker.h"
#import "NetworkActivityViewController.h"
#import "GeneratePasswordViewController.h"
#import "KdbGroupViewController.h"

@class KdbGroupViewController;

@interface EditEntryViewController : NetworkActivityViewController<ParentGroupPickerDelegate, UITextFieldDelegate, IconPickerDelegate, DatabaseDelegate, GeneratePasswordDelegate, UITextViewDelegate> {
    KdbGroup *parentGroup;
    KdbEntry *kdbEntry;
    NSString *neuName;
    UIImage *neuIcon;
    uint32_t neuIconId;
    NSString *neuUsername;
    NSString *neuPassword;
    NSString *verifyPassword;
    NSString *neuUrl;
    NSString *neuNotes;
    NSDate *neuExpireDate;
    BOOL editMode;
    int currentFirstResponder;
    KdbGroupViewController *masterView;
    UIPopoverController *iconPop;
    NSIndexPath *scrollToPath;
    int oldkeyboardHeight;
    BOOL keyboardShowing;
}

@property (retain, nonatomic) KdbGroup *parentGroup;
@property (retain, nonatomic) KdbEntry *kdbEntry;
@property (nonatomic) BOOL editMode;
@property (retain, nonatomic) UIImage *neuIcon;
@property (nonatomic) uint32_t neuIconId;
@property (copy, nonatomic) NSString *neuName;
@property (copy, nonatomic) NSString *neuUsername;
@property (copy, nonatomic) NSString *neuPassword;
@property (copy, nonatomic) NSString *verifyPassword;
@property (copy, nonatomic) NSString *neuUrl;
@property (copy, nonatomic) NSString *neuNotes;
@property (copy, nonatomic) NSDate *neuExpireDate;
@property (retain, nonatomic) KdbGroupViewController *masterView;
@property (retain, nonatomic) UIPopoverController *iconPop;
@property (retain, nonatomic) NSIndexPath *scrollToPath;

- (UITableView*) tableView;

@end