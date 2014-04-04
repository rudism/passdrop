//
//  Database.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "kpass.h"
//#import "KdbGroup.h"

@class KdbGroup;
@class DatabaseManager;
@protocol DatabaseDelegate;

@protocol Database<NSObject>

@property (retain, nonatomic) NSString *localPath;
@property (retain, nonatomic) NSString *identifier;
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSDate *lastModified;
@property (nonatomic) long long revision;
@property (retain, nonatomic) NSDate *lastSynced;
@property (assign, nonatomic) id<DatabaseDelegate> delegate;
@property (assign, nonatomic) id<DatabaseDelegate> savingDelegate;
@property (assign, nonatomic) DatabaseManager *dbManager;
@property (nonatomic) BOOL isReadOnly;
@property (assign, nonatomic) kpass_db *kpDatabase;
@property (assign, nonatomic) uint8_t *pwHash;
@property (nonatomic) BOOL isDirty;
@property (retain, nonatomic) NSString *rev;

- (NSString*)location;
- (NSString*)lastError;
- (BOOL)loadWithPassword:(NSString*)password;
- (KdbGroup*)rootGroup;
- (void)lockForEditing;
- (void)removeLock;
- (void)update;

- (NSDate*)parseDate:(uint8_t*)dtime;
- (void)packDate:(NSDate*)date toBuffer:(uint8_t*)buffer;

- (void)save;
- (void)saveWithPassword:(NSString*)password;
- (void)syncWithForce:(BOOL)force;
- (void)discardChanges;

- (uint32_t)nextGroupId;

@end

@protocol DatabaseDelegate<NSObject>

@optional
- (void)databaseWasLockedForEditing:(id<Database>)database;
- (void)databaseWasAlreadyLocked:(id<Database>)database;
- (void)database:(id<Database>)database failedToLockWithReason:(NSString*)reason;
- (void)databaseLockWasRemoved:(id<Database>)database;
- (void)database:(id<Database>)database failedToRemoveLockWithReason:(NSString*)reason;
- (void)databaseUpdateComplete:(id<Database>)database;
- (void)databaseUpdateWouldOverwriteChanges:(id<Database>)database;
- (void)databaseWasDeleted:(id<Database>)database;
- (void)database:(id<Database>)database updateFailedWithReason:(NSString*)error;
- (void)database:(id<Database>)database saveFailedWithReason:(NSString*)error;
- (void)databaseSaveComplete:(id<Database>)database;
- (void)database:(id<Database>)database syncFailedWithReason:(NSString*)error;
- (void)databaseSyncComplete:(id<Database>)database;
- (void)databaseSyncWouldOverwriteChanges:(id<Database>)database;

@end