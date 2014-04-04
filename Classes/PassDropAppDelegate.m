//
//  PassDropAppDelegate.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PassDropAppDelegate.h"
#import "Global.h"
#import "RootViewController.h"
#import "SettingsViewController.h"

@implementation PassDropAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize splitController;
@synthesize dbSession;
@synthesize prefs;
@synthesize dbManager;
@synthesize rootView;
@synthesize settingsView;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
	prefs = [[AppPrefs alloc] init];
	[prefs loadPrefs];
	
	dbSession = [[DBSession alloc] initWithAppKey:DROPBOX_KEY appSecret:DROPBOX_SECRET root:kDBRootDropbox];
	[DBSession setSharedSession:dbSession];
	[dbSession release];
	
	dbManager = [[DatabaseManager alloc] init];
    
    // Add the navigation controller's view to the window and display.
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        splitController.showsMasterInLandscape = YES;
        splitController.showsMasterInPortrait = YES;
        [self.window setRootViewController:splitController];
    } else {
        [self.window setRootViewController:navigationController];
    }
    [self.window makeKeyAndVisible];
    
    isLocked = true;
    bgTimer = nil;
    hide = [[HideViewController alloc] initWithNibName:@"HideScreenView" bundle:nil];

    return YES;
}

- (void)dropboxWasReset {
	[dbManager dropboxWasReset];
	[rootView dropboxWasReset];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    BOOL isHidden = [navigationController topViewController] == hide || splitController.modalViewController == hide;
    if(!isHidden && dbManager.activeDatabase != nil && prefs.lockInBackgroundSeconds >= 0){
        bgTimer = [[NSDate date] retain];
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            NSArray *details = [(UINavigationController*)splitController.detailViewController viewControllers];
            if(details.count > 1){
                if([[details objectAtIndex:1] respondsToSelector:@selector(hideKeyboard)]){
                    [[details objectAtIndex:1] hideKeyboard];
                }
            }
            [splitController presentModalViewController:hide animated:NO];
        } else {
            [navigationController dismissModalViewControllerAnimated:NO];
            [navigationController pushViewController:hide animated:NO];
            [navigationController setNavigationBarHidden:YES];
        }
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 1){
        if(buttonIndex == 0){
            [self userClosedPasswordModal:[dbManager activeDatabase]];
        } else {
            if([alertView textFieldAtIndex:0].text.length > 0){
                if([dbManager.activeDatabase loadWithPassword:[alertView textFieldAtIndex:0].text]){
                    [self userUnlockedDatabase:[dbManager activeDatabase]];
                } else {
                    UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:@"Enter Password" message:@"Please try again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlock", nil];
                    dialog.tag = 1;
                    dialog.alertViewStyle = UIAlertViewStyleSecureTextInput;
                    [dialog show];
                    [dialog release];
                }
            } else {
                UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:@"Enter Password" message:@"You must enter the password." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlock", nil];
                dialog.tag = 1;
                dialog.alertViewStyle = UIAlertViewStyleSecureTextInput;
                [dialog show];
                [dialog release];
            }
        }
    }
}

- (void)userUnlockedDatabase:(id<Database>)database {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [splitController dismissModalViewControllerAnimated:NO];
    } else {
        if([navigationController topViewController] == hide){
            [navigationController popViewControllerAnimated:NO];
            [navigationController setNavigationBarHidden:NO];
        }
    }
}

- (void)userClosedPasswordModal:(id<Database>)database {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [(UINavigationController*)splitController.detailViewController popToRootViewControllerAnimated:NO];
        [rootView.navigationController popToRootViewControllerAnimated:NO];
        [rootView.navigationController.view setAlpha:1.0f];
        [splitController dismissModalViewControllerAnimated:NO];
        dbManager.activeDatabase = nil;
        [rootView removeLock:database];
    } else {
        if([navigationController topViewController] == hide){
            [navigationController popViewControllerAnimated:NO];
            [navigationController setNavigationBarHidden:NO];
        }
        [navigationController popToRootViewControllerAnimated:NO];
        dbManager.activeDatabase = nil;
        [rootView removeLock:database];
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [settingsView updateSettingsUI];
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
        if(bgTimer != nil){
            NSTimeInterval diff = fabs([bgTimer timeIntervalSinceNow]);
            //[navigationController dismissModalViewControllerAnimated:NO];
            if(diff > prefs.lockInBackgroundSeconds){
                UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:@"Enter Password" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlock", nil];
                dialog.tag = 1;
                dialog.alertViewStyle = UIAlertViewStyleSecureTextInput;
                [dialog show];
                [dialog release];
            } else {
                if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                    [splitController dismissModalViewControllerAnimated:NO];
                } else {
                    if([navigationController topViewController] == hide){
                        [navigationController popViewControllerAnimated:NO];
                        [navigationController setNavigationBarHidden:NO];
                    }
                }
            }
            [bgTimer release];
            bgTimer = nil;
        }

    if(prefs.autoClearClipboard == YES){
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = @"";
    }
    
    [settingsView updateSettingsUI];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[dbManager release];
	[prefs release];
    [hide release];
	[navigationController release];
    [splitController release];
	[window release];
    [rootView release];
	[super dealloc];
}


@end

