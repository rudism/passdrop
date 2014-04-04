//
//  NewDatabaseViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 9/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "NetworkActivityViewController.h"
#import "KdbReader.h"
#import "KdbWriter.h"

@protocol NewDatabaseDelegate;

@interface NewDatabaseViewController : NetworkActivityViewController<UITextFieldDelegate, DBRestClientDelegate> {
    DBRestClient *restClient;
    NSString *dbName;
    NSString *password;
    NSString *verifyPassword;
    NSString *location;
    int currentFirstResponder;
    id<NewDatabaseDelegate> delegate;
    int oldkeyboardHeight;
    BOOL keyboardShowing;
    NSIndexPath *scrollToPath;
}

@property (retain, nonatomic) DBRestClient *restClient;
@property (retain, nonatomic) NSString *dbName;
@property (retain, nonatomic) NSString *password;
@property (retain, nonatomic) NSString *verifyPassword;
@property (retain, nonatomic) NSString *location;
@property (nonatomic) int currentFirstResponder;
@property (retain, nonatomic) id<NewDatabaseDelegate> delegate;
@property (retain, nonatomic) NSIndexPath *scrollToPath;

- (UITableView*) tableView;

@end

@protocol NewDatabaseDelegate <NSObject>

- (void)newDatabaseCreated:(NSString*)path;

@end