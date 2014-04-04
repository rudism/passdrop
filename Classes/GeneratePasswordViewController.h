//
//  GeneratePasswordViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 9/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PassDropAppDelegate.h"
#import "LoadingView.h"

@protocol GeneratePasswordDelegate;

@interface GeneratePasswordViewController : UIViewController<UITextFieldDelegate> {
    id<GeneratePasswordDelegate> delegate;
    int currentFirstResponder;
    NSString *password;
    PassDropAppDelegate *app;
    
    BOOL pwUpper;
    BOOL pwLower;
    BOOL pwNumbers;
    BOOL pwSpaces;
    BOOL pwMinus;
    BOOL pwUnderline;
    BOOL pwSpecials;
    BOOL pwExcludes;
    BOOL pwDiversity;
    BOOL pwReveal;
    int pwLength;
    BOOL pwBrackets;
    BOOL pwPunctuation;
    int oldkeyboardHeight;
    BOOL keyboardShowing;
}

@property (retain, nonatomic) NSString *password;
@property (retain, nonatomic) id<GeneratePasswordDelegate> delegate;

- (UITableView*) tableView;
- (void) generatePassword;

@end

@protocol GeneratePasswordDelegate<NSObject>

- (void)passwordGenerated:(NSString*)password;

@end