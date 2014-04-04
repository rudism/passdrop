//
//  DatabaseManager.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DatabaseManager.h"


@implementation DatabaseManager

@synthesize databases;
@synthesize dataPath;
@synthesize configFile;
@synthesize delegate;
@synthesize activeDatabase;

- (id) init {
	if((self = [super init])){
		NSFileManager *fileManager = [[NSFileManager alloc] init];
	#if TARGET_IPHONE_SIMULATOR
		self.dataPath = @"/Users/rudism/Documents/PassDrop";
	#else
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		self.dataPath = [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:@"PassDrop"];
		
		if(![fileManager fileExistsAtPath:dataPath]){
			[fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
	#endif
		configFile = [[dataPath stringByAppendingPathComponent:@"databases.archive"] retain];
		if(![fileManager fileExistsAtPath:configFile]){
			self.databases = [[[NSMutableArray alloc] init] autorelease];
			[self save];
		}
		
		self.databases = [NSKeyedUnarchiver unarchiveObjectWithFile:configFile];

		[fileManager release];
        
        if(![[DBSession sharedSession] isLinked] && databases.count > 0){
            [self dropboxWasReset];
        }
	}
	return self;
}

- (void) save {
	[NSKeyedArchiver archiveRootObject:databases toFile:configFile];
}

- (NSString*) getIdentifierForDatabase:(NSString*)localId {
	// only supports dropbox right now anyway, so just use the same id
	return [@"/dropbox" stringByAppendingString:localId];
}

- (BOOL) databaseExists:(NSString*)dbId {
	for(NSMutableDictionary *dbData in databases){
		if([[dbData objectForKey:kDatabaseId] isEqualToString:dbId]){
			return YES;
		}
	}
	return NO;
}

- (NSString*) getLocalFilenameForDatabase:(NSString*)dbId forNewFile:(BOOL)isNew {
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *fileName = [dbId lastPathComponent];
	if(isNew){
		int count = 0;
		NSString *baseFileName = [NSString stringWithString:fileName];
		while([fileManager fileExistsAtPath:[dataPath stringByAppendingPathComponent:fileName]]){
			fileName = [NSString stringWithFormat:@"%d_%@", count++, baseFileName];
		}
	}
	[fileManager release];
	return [dataPath stringByAppendingPathComponent:fileName];
}

- (void) createNewDatabaseNamed:(NSString*)name withId:(NSString*)dbId withLocalPath:(NSString*)localPath lastModified:(NSDate*)lastModified revision:(long long)revision {
	NSMutableDictionary *dbData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
								   [NSString stringWithString:name], kDatabaseName,
								   [NSString stringWithString:dbId], kDatabaseId,
								   [[NSString stringWithString:localPath] lastPathComponent], kDatabaseLocalPath,
								   lastModified, kDatabaseLastModified,
								   [NSNumber numberWithLongLong:revision], kDatabaseRevision,
								   [NSDate date], kDatabaseLastSynced, // assume that new database was just downloaded prior to creation
								   nil]; 
	[databases addObject:dbData];
	[self save];
	[dbData release];
	if(delegate != nil){
		[delegate databaseWasAdded:name];
	}
}

- (void) moveDatabaseAtIndex:(int)fromIndex toIndex:(int)toIndex {
	NSMutableDictionary *db = [[databases objectAtIndex:fromIndex] retain];
	[databases removeObjectAtIndex:fromIndex];
	[databases insertObject:db atIndex:toIndex];

	[db release];
	[self save];
}

- (void) deleteDatabaseAtIndex:(int)index {
	// delete the local file
	NSString *filePath = [dataPath stringByAppendingPathComponent:[[[databases objectAtIndex:index] objectForKey:kDatabaseLocalPath] lastPathComponent]];
    NSString *tmpPath = [filePath stringByAppendingPathExtension:@"tmp"];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	if([fileManager fileExistsAtPath:filePath]){
		[fileManager removeItemAtPath:filePath error:nil];
	}
    if([fileManager fileExistsAtPath:tmpPath]){
        [fileManager removeItemAtPath:tmpPath error:nil];
    }
	[fileManager release];
	[databases removeObjectAtIndex:index];
	[self save];
}

- (id<Database>) getDatabaseAtIndex:(int)index {
	// only supports dropbox for now, in future move this to a factory
	NSMutableDictionary *dbData = [databases objectAtIndex:index];
	id<Database> database = [[[DropBoxDatabase alloc] init] autorelease];
	database.identifier = [NSString stringWithString:[dbData objectForKey:kDatabaseId]];
	database.name = [NSString stringWithString:[dbData objectForKey:kDatabaseName]];
	database.localPath = [dataPath stringByAppendingPathComponent:[[NSString stringWithString:[dbData objectForKey:kDatabaseLocalPath]] lastPathComponent]];
	database.lastModified = [[[dbData objectForKey:kDatabaseLastModified] copy] autorelease];
	database.revision = [[dbData objectForKey:kDatabaseRevision] longLongValue];
	database.lastSynced = [[[dbData objectForKey:kDatabaseLastSynced] copy] autorelease];
    NSFileManager *fm = [[NSFileManager alloc] init];
    database.isDirty = [fm fileExistsAtPath:[database.localPath stringByAppendingPathExtension:@"tmp"]];
    [fm release];
	database.dbManager = self;
	return database;
}

- (int) getIndexOfDatabase:(id<Database>)database {
    for(int i = 0; i < databases.count; i++){
        if([database.identifier isEqualToString:[[databases objectAtIndex:i] objectForKey:kDatabaseId]]){
            return i;
        }
    }
    return -1;
}

- (void) updateDatabase:(id<Database>)database {
	// find the database in our array
	for(NSMutableDictionary *dbData in databases){
		if([[dbData objectForKey:kDatabaseId] isEqualToString:database.identifier]){
			[dbData removeObjectForKey:kDatabaseName];
			[dbData removeObjectForKey:kDatabaseLastModified];
			[dbData removeObjectForKey:kDatabaseLastSynced];
			[dbData setObject:[NSString stringWithString:database.name] forKey:kDatabaseName];
			[dbData setObject:[[database.lastModified copy] autorelease] forKey:kDatabaseLastModified];
			[dbData setObject:[[database.lastSynced copy] autorelease] forKey:kDatabaseLastSynced];
			[dbData setObject:[NSNumber numberWithLongLong:database.revision] forKey:kDatabaseRevision];
			[self save];
			return;
		}
	}
}

#pragma mark - memory management

- (void) dropboxWasReset {
	while([databases count] > 0){
		[self deleteDatabaseAtIndex:0];
	}
}

- (void) dealloc {
	[databases release];
	[dataPath release];
	[configFile release];
	[super dealloc];
}

@end
