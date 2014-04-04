//
//  DatabaseManager.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "DropBoxDatabase.h"

#define kDatabaseName @"name"
#define kDatabaseId @"id"
#define kDatabaseLocalPath @"path"
#define kDatabaseLastModified @"lastmod"
#define kDatabaseLastSynced @"synced"
#define kDatabaseRevision @"rev"

@protocol DatabaseManagerDelegate;

@interface DatabaseManager : NSObject {
	NSMutableArray *databases;
	NSString *dataPath;
	NSString *configFile;
	id<DatabaseManagerDelegate> delegate;
    id<Database> activeDatabase;
}

@property (retain, nonatomic) NSMutableArray *databases;
@property (retain, nonatomic) NSString *dataPath;
@property (retain, nonatomic) NSString *configFile;
@property (assign, nonatomic) id<DatabaseManagerDelegate> delegate;
@property (assign, nonatomic) id<Database> activeDatabase;

- (void) save;
- (NSString*) getIdentifierForDatabase:(NSString*)localId;
- (BOOL) databaseExists:(NSString*)dbId;
- (NSString*) getLocalFilenameForDatabase:(NSString*)dbId forNewFile:(BOOL)isNew;
- (void) createNewDatabaseNamed:(NSString*)name withId:(NSString*)dbId withLocalPath:(NSString*)localPath lastModified:(NSDate*)lastModified revision:(long long)revision;
- (id<Database>) getDatabaseAtIndex:(int)index;
- (int) getIndexOfDatabase:(id<Database>)database;
- (void) moveDatabaseAtIndex:(int)fromIndex toIndex:(int)toIndex;
- (void) deleteDatabaseAtIndex:(int)index;
- (void) dropboxWasReset;
- (void) updateDatabase:(id<Database>)database;


@end

@protocol DatabaseManagerDelegate

- (void)databaseWasAdded:(NSString*)databaseName;

@end