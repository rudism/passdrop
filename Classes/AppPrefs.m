//
//  AppPrefs.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppPrefs.h"


@implementation AppPrefs

@synthesize autoClearClipboard;
@synthesize lockInBackgroundSeconds;
@synthesize firstLoad;
@synthesize databaseOpenMode;
@synthesize pwUpper;
@synthesize pwLower;
@synthesize pwNumbers;
@synthesize pwSpaces;
@synthesize pwMinus;
@synthesize pwUnderline;
@synthesize pwSpecials;
@synthesize pwExcludes;
@synthesize pwDiversity;
@synthesize pwReveal;
@synthesize pwLength;
@synthesize pwBrackets;
@synthesize pwPunctuation;
@synthesize lastVersion;
@synthesize ignoreBackup;

- (void) loadPrefs {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// set up defaults
	NSNumber *defLockSeconds = [NSNumber numberWithInt:30];
	NSNumber *defDatabaseOpenMode = [NSNumber numberWithInt:kOpenModeReadOnly];
	NSNumber *defOpenLast = [NSNumber numberWithBool:YES];
	NSNumber *defFirstLoad = [NSNumber numberWithBool:YES];
    NSNumber *defIgnoreBackup = [NSNumber numberWithBool:YES];
    
    NSNumber *defSwitchOn = [NSNumber numberWithBool:YES];
    NSNumber *defSwitchOff = [NSNumber numberWithBool:NO];
    NSNumber *defPwLength = [NSNumber numberWithInt:12];
    
    NSNumber *defVersion = [NSNumber numberWithDouble:1.01];
    
	NSDictionary *defaults = [[NSDictionary alloc] initWithObjectsAndKeys:defOpenLast, kOpenLastDatabase, defLockSeconds, kLockInBackgroundSeconds, defFirstLoad, kFirstLoad, defDatabaseOpenMode, kDatabaseOpenMode, defSwitchOn, kPwUpper, defSwitchOn, kPwLower, defSwitchOn, kPwNumbers, defSwitchOff, kPwSpaces, defSwitchOn, kPwMinus, defSwitchOn, kPwUnderline, defSwitchOn, kPwSpecials, defSwitchOff, kPwExcludes, defSwitchOff, kPwDiversity, defSwitchOff, kPwReveal, defPwLength, kPwLength, defSwitchOff, kPwBrackets, defSwitchOff, kPwPunctuation, defVersion, kLastVersion, defIgnoreBackup, kIgnoreBackup, nil];
	[prefs registerDefaults:defaults];
	
	firstLoad = [prefs boolForKey:kFirstLoad];
	autoClearClipboard = [prefs boolForKey:kOpenLastDatabase];
	lockInBackgroundSeconds = [prefs integerForKey:kLockInBackgroundSeconds];
	databaseOpenMode = [prefs integerForKey:kDatabaseOpenMode];
    lastVersion = [prefs doubleForKey:kLastVersion];
    ignoreBackup = [prefs boolForKey:kIgnoreBackup];
    
    pwUpper = [prefs boolForKey:kPwUpper];
	pwLower = [prefs boolForKey:kPwLower];
    pwNumbers = [prefs boolForKey:kPwNumbers];
    pwSpaces = [prefs boolForKey:kPwSpaces];
    pwMinus = [prefs boolForKey:kPwMinus];
    pwUnderline = [prefs boolForKey:kPwUnderline];
    pwSpecials = [prefs boolForKey:kPwSpecials];
    pwExcludes = [prefs boolForKey:kPwExcludes];
    pwDiversity = [prefs boolForKey:kPwDiversity];
    pwReveal = [prefs boolForKey:kPwReveal];
    pwLength = [prefs integerForKey:kPwLength];
    pwBrackets = [prefs boolForKey:kPwBrackets];
    pwPunctuation = [prefs boolForKey:kPwPunctuation];
    
	[defaults release];
}

- (void) savePrefs {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setBool:firstLoad forKey:kFirstLoad];
	[prefs setBool:autoClearClipboard forKey:kOpenLastDatabase];
	[prefs setInteger:lockInBackgroundSeconds forKey:kLockInBackgroundSeconds];
	[prefs setInteger:databaseOpenMode forKey:kDatabaseOpenMode];
    [prefs setBool:ignoreBackup forKey:kIgnoreBackup];
    [prefs setDouble:1.2 forKey:kLastVersion];
    self.lastVersion = 1.2;
    
    [prefs setBool:pwUpper forKey:kPwUpper];
    [prefs setBool:pwLower forKey:kPwLower];
    [prefs setBool:pwNumbers forKey:kPwNumbers];
    [prefs setBool:pwSpaces forKey:kPwSpaces];
    [prefs setBool:pwMinus forKey:kPwMinus];
    [prefs setBool:pwUnderline forKey:kPwUnderline];
    [prefs setBool:pwSpecials forKey:kPwSpecials];
    [prefs setBool:pwExcludes forKey:kPwExcludes];
    [prefs setBool:pwDiversity forKey:kPwDiversity];
    [prefs setBool:pwReveal forKey:kPwReveal];
    [prefs setInteger:pwLength forKey:kPwLength];
    [prefs setBool:pwBrackets forKey:kPwBrackets];
    [prefs setBool:pwPunctuation forKey:kPwPunctuation];
    
	[prefs synchronize];
}

@end
