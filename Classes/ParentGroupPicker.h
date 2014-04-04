//
//  ParentGroupPicker.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 7/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KdbGroup.h"

@protocol ParentGroupPickerDelegate;

@interface ParentGroupPicker : UIViewController<UITableViewDataSource, UISearchDisplayDelegate> {
    KdbGroup *kdbGroup;
    NSMutableArray *searchResults;
    NSString *savedSearchTerm;
    id<ParentGroupPickerDelegate> delegate;
    BOOL showNone;
}

@property (retain, nonatomic) KdbGroup *kdbGroup;
@property (retain, nonatomic) NSMutableArray *searchResults;
@property (retain, nonatomic) NSString *savedSearchTerm;
@property (assign, nonatomic) id<ParentGroupPickerDelegate> delegate;
@property (nonatomic) BOOL showNone;

- (UITableView*) tableView;

@end

@protocol ParentGroupPickerDelegate<NSObject>

- (void)parentGroupSelected:(KdbGroup*)group;
- (UIViewController*)viewController;
- (KdbGroup*)childGroup;

@end