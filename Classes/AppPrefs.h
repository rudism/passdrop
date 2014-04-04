//
//  AppPrefs.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kOpenLastDatabase @"openLastDatabase"
#define kFirstLoad @"firstLoad"
#define kLockInBackgroundSeconds @"lockInBackgroundSeconds"
#define kDatabaseOpenMode @"openDatabaseMode"
#define kLastVersion @"lastVersion"
#define kIgnoreBackup @"ignoreBackup"

#define kOpenModeWritable 0
#define kOpenModeReadOnly 1
#define kOpenModeAlwaysAsk 2

#define kPwUpper @"pwUpper"
#define kPwLower @"pwLower"
#define kPwNumbers @"pwNumbers"
#define kPwSpaces @"pwSpaces"
#define kPwMinus @"pwMinus"
#define kPwUnderline @"pwUnderscore"
#define kPwSpecials @"pwSpecials"
#define kPwExcludes @"pwExcludes"
#define kPwDiversity @"pwDiversity"
#define kPwReveal @"pwReveal"
#define kPwLength @"pwLength"
#define kPwBrackets @"pwBrackets"
#define kPwPunctuation @"pwPunctuation"

@interface AppPrefs : NSObject {
	BOOL firstLoad;
	BOOL autoClearClipboard;
	int lockInBackgroundSeconds;
	int databaseOpenMode;
    double lastVersion;
    
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
    BOOL ignoreBackup;
}

@property (nonatomic) BOOL firstLoad;
@property (nonatomic) BOOL autoClearClipboard;
@property (nonatomic) int lockInBackgroundSeconds;
@property (nonatomic) int databaseOpenMode;
@property (nonatomic) BOOL pwUpper;
@property (nonatomic) BOOL pwLower;
@property (nonatomic) BOOL pwNumbers;
@property (nonatomic) BOOL pwSpaces;
@property (nonatomic) BOOL pwMinus;
@property (nonatomic) BOOL pwUnderline;
@property (nonatomic) BOOL pwSpecials;
@property (nonatomic) BOOL pwExcludes;
@property (nonatomic) BOOL pwDiversity;
@property (nonatomic) BOOL pwReveal;
@property (nonatomic) BOOL ignoreBackup;
@property (nonatomic) int pwLength;
@property (nonatomic) BOOL pwBrackets;
@property (nonatomic) BOOL pwPunctuation;
@property (nonatomic) double lastVersion;

- (void) loadPrefs;
- (void) savePrefs;

@end
