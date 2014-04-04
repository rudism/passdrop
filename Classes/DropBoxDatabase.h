//
//  DropBoxDatabase.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define LOADING_LOCK_FILE 1
#define LOADING_DB_FILE 2
#define SENDING_DB_FILE 3
#define UPDATING_DB_REVISION 4

#import <Foundation/Foundation.h>
#import "Database.h"
#import "KdbReader.h"
#import "KdbWriter.h"
#import <DropboxSDK/DropboxSDK.h>
#import "DatabaseManager.h"

@interface DropBoxDatabase : NSObject<Database, DBRestClientDelegate> {
	DBRestClient *restClient;
	NSString *localPath;
	NSString *identifier;
	NSString *name;
	NSDate *lastModified;
	NSDate *lastSynced;
	id<DatabaseDelegate> delegate;
    id<DatabaseDelegate> savingDelegate;
	NSString *lastError;
	KdbGroup *kdbGroup;
	BOOL isReadOnly;
    kpass_db *kpDatabase;
    uint8_t *pwHash;
}

@property (retain, nonatomic) NSString *localPath;
@property (retain, nonatomic) NSString *identifier;
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSDate *lastModified;
@property (retain, nonatomic) NSDate *lastSynced;
@property (assign, nonatomic) id<DatabaseDelegate> delegate;
@property (assign, nonatomic) id<DatabaseDelegate> savingDelegate;
@property (retain, nonatomic) KdbGroup *kdbGroup;
@property (retain, nonatomic) DBRestClient *restClient;
@property (assign, nonatomic) kpass_db *kpDatabase;
@property (assign, nonatomic) uint8_t *pwHash;

@end