//
//  DropBoxDatabase.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DropBoxDatabase.h"


@implementation DropBoxDatabase

@synthesize localPath;
@synthesize identifier;
@synthesize name;
@synthesize delegate;
@synthesize savingDelegate;
@synthesize lastModified;
@synthesize lastSynced;
@synthesize kdbGroup;
@synthesize restClient;
@synthesize isReadOnly;
@synthesize dbManager;
@synthesize revision;
@synthesize kpDatabase;
@synthesize pwHash;
@synthesize isDirty;
@synthesize rev;

int mode; // 0 = none, 1 = uploading lock file
DBMetadata *tempMeta;

- (id)init {
	if((self = [super init])){
		restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		restClient.delegate = self;
		mode = 0;
	}
	return self;
}

#pragma - Database loading stuff

- (NSString*)location {
	return [identifier substringFromIndex:8]; // trim the "/dropbox" from the identifier to get the location
}

- (BOOL)loadWithPassword:(NSString*)password {
	BOOL success = YES;
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    isDirty = [fm fileExistsAtPath:[self.localPath stringByAppendingPathExtension:@"tmp"]];
    [fm release];
    
	KdbReader *kdb = [[KdbReader alloc] initWithKdbFile:isDirty ? [self.localPath stringByAppendingPathExtension:@"tmp"] : self.localPath usingPassword:password];
	if([kdb hasError]){
		[lastError release];
		lastError = [[NSString stringWithString:kdb.lastError] retain];
		success = NO;
	} else {
		self.kdbGroup = [kdb getRootGroupForDatabase:self];
	}
	[kdb release];
	return success;
}

- (NSString*)lastError {
	return lastError;
}

- (void)lockForEditing {
	mode = 1;
	[restClient loadMetadata:[self.location stringByAppendingString:@".lock"]];
}

- (KdbGroup*)rootGroup {
	return kdbGroup;
}

- (void)uploadLockFile {
	NSString *dataPath;
	NSFileManager *fileManager = [[NSFileManager alloc] init];
#if TARGET_IPHONE_SIMULATOR
	dataPath = @"/Users/rudism/Documents/PassDrop";
#else
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	dataPath = [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:@"PassDrop"];
#endif
	NSString *fname = [[[self location] lastPathComponent] stringByAppendingString:@".lock"];
	NSString *localLock = [dataPath stringByAppendingPathComponent:@"lock"];
	if(![fileManager fileExistsAtPath:localLock]){
		[fileManager createFileAtPath:localLock contents:[[[NSData alloc] init] autorelease] attributes:nil];
	}
	[fileManager release];
	
	mode = LOADING_LOCK_FILE;
	[restClient uploadFile:fname toPath:[[self location] stringByDeletingLastPathComponent] fromPath:localLock];
}

- (void)removeLock {
	[restClient deletePath:[[self location] stringByAppendingString:@".lock"]];
}

- (void)update {
	// get metedata for last modified date
	mode = LOADING_DB_FILE;
    NSFileManager *fm = [[NSFileManager alloc] init];
    isDirty = [fm fileExistsAtPath:[self.localPath stringByAppendingPathExtension:@"tmp"]];
    [fm release];
	[restClient loadMetadata:[self location]];
}

- (void)upload {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSString *newDb = [self.localPath stringByAppendingPathExtension:@"tmp"];
    
    if([fileManager fileExistsAtPath:newDb]){
        // upload the database
        [restClient uploadFile:[[self location] lastPathComponent] toPath:[[self location] stringByDeletingLastPathComponent] fromPath:newDb];
    } else {
        [savingDelegate database:self syncFailedWithReason:@"The modified database could not be found."];
    }
    
    [fileManager release];
}

- (void)syncWithForce:(BOOL)force {
    if(!force){
        // check if we're overwriting other changes
        mode = SENDING_DB_FILE;
        [restClient loadMetadata:[self location]];
    } else {
        mode = SENDING_DB_FILE;
        [self upload];
    }
}

#pragma mark - Database stuff

- (void)save {
    // save to temp file
    KdbWriter *writer = [[KdbWriter alloc] init];
    NSString *tmpPath = [localPath stringByAppendingString:@".tmp"];
    if([writer saveDatabase:kpDatabase withPassword:pwHash toFile:tmpPath] == YES){
        // call success method on delegate
        if([savingDelegate respondsToSelector:@selector(databaseSaveComplete:)]){
            [savingDelegate databaseSaveComplete:self];
            isDirty = YES;
            self.lastModified = [NSDate date];
            [dbManager updateDatabase:self];
        }
    } else {
        // call fail method on delegate
        if([savingDelegate respondsToSelector:@selector(database:saveFailedWithReason:)]){
            [savingDelegate database:self saveFailedWithReason:[writer lastError]];
        }
    }
    [writer release];
}

- (void)saveWithPassword:(NSString *)password {
    const char *cPw = [password cStringUsingEncoding:NSUTF8StringEncoding];
    if(pwHash) free(pwHash);
    pwHash = malloc(sizeof(uint8_t)*32);
    kpass_retval retval = kpass_hash_pw(kpDatabase, cPw, pwHash);
    if(retval != kpass_success){
        [savingDelegate database:self saveFailedWithReason:@"There was a problem with your new password."];
        return;
    }
    [self save];
}

- (uint32_t)nextGroupId {
    BOOL found = NO;
    uint32_t nextId;
    do {
        nextId = arc4random();
        found = YES;
        for(int i = 0; i < kpDatabase->groups_len; i++){
            if(kpDatabase->groups[i]->id == nextId){
                found = NO;
                continue;
            }
        }
    } while(!found);
    
    return nextId;
}

- (void)discardChanges {
    self.revision = 0;
    self.rev = nil;
    self.isDirty = NO;
    [dbManager updateDatabase:self];
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    [fm removeItemAtPath:[self.localPath stringByAppendingPathExtension:@"tmp"] error:nil];
    [fm release];
}

#pragma mark -
#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
	if(mode == LOADING_LOCK_FILE){ // lock file
		if(!metadata.isDeleted){
			[delegate databaseWasAlreadyLocked:self];
		} else {
			[self uploadLockFile];
		}
	} else if (mode == LOADING_DB_FILE) { // database file
		if(!metadata.isDeleted){
			if(self.revision != metadata.revision){
                if(self.isDirty){
                    [delegate databaseUpdateWouldOverwriteChanges:self];
                } else {
                    // need to download newer revision
                    tempMeta = [metadata retain];
                    [restClient loadFile:[self location] intoPath:self.localPath];
                }
			} else {
				// already have latest revision
				[delegate databaseUpdateComplete:self];
			}
		} else {
			[delegate databaseWasDeleted:self];
		}
	} else if(mode == SENDING_DB_FILE){
        if(!metadata.isDeleted){
            if(self.revision != metadata.revision){
                [savingDelegate databaseSyncWouldOverwriteChanges:self];
            } else {
                [self upload];
            }
        } else {
            [savingDelegate databaseWasDeleted:self];
        }
    } else if(mode == UPDATING_DB_REVISION){
        self.revision = metadata.revision;
        self.rev = metadata.rev;
        self.isDirty = NO;
        self.lastSynced = [NSDate date];
        [dbManager updateDatabase:self];
        [savingDelegate databaseSyncComplete:self];
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
	if(mode == LOADING_LOCK_FILE){ // lock file
		if([error code] == 404){
			[self uploadLockFile];
		} else {
			NSString *msg = @"There was an error locking the database.";
			if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
				msg = [[error userInfo] objectForKey:@"error"];
			}
			[delegate database:self failedToLockWithReason:msg];
		}
	} else if(mode == LOADING_DB_FILE){ // database file
		NSString *msg = @"There was an error updating the database.";
		if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
			msg = [[error userInfo] objectForKey:@"error"];
		}
		[delegate database:self updateFailedWithReason:msg];
	} else if(mode == SENDING_DB_FILE){ // database file
		NSString *msg = @"There was an error uploading the database.";
		if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
			msg = [[error userInfo] objectForKey:@"error"];
		}
		[savingDelegate database:self syncFailedWithReason:msg];
    } else if(mode == UPDATING_DB_REVISION){
        NSString *msg = @"The database was uploaded to DropBox, but there was an error retrieving the revision number afterwards.";
        if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
			msg = [[error userInfo] objectForKey:@"error"];
		}
		[savingDelegate database:self syncFailedWithReason:msg];
    }
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath {
	if(mode == LOADING_LOCK_FILE){
		[delegate databaseWasLockedForEditing:self];
	} else if(mode == SENDING_DB_FILE){
        NSString *tmpFile = [self.localPath stringByAppendingPathExtension:@"tmp"];
        NSFileManager *fm = [[NSFileManager alloc] init];
        if(![fm removeItemAtPath:self.localPath error:nil] || ![fm copyItemAtPath:tmpFile toPath:self.localPath error:nil] || ![fm removeItemAtPath:tmpFile error:nil]){
            [savingDelegate database:self syncFailedWithReason:@"The database was uploaded successfully, but a filesystem error prevented the local copy from being updated."];
        } else {
            mode = UPDATING_DB_REVISION;
            [restClient loadMetadata:[self location]];
        }
        [fm release];
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
	if(mode == LOADING_LOCK_FILE){
		NSString *msg = @"There was an error uploading the lock file.";
		if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
			msg = [[error userInfo] objectForKey:@"error"];
		}
		[delegate database:self failedToLockWithReason:msg];
	} else if(mode == SENDING_DB_FILE){
        NSString *msg = @"There was an error uploading the database file.";
        if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
			msg = [[error userInfo] objectForKey:@"error"];
		}
        [savingDelegate database:self syncFailedWithReason:msg];
    }
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path {
	[delegate databaseLockWasRemoved:self];
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error {
	NSString *msg = @"There was an error removing the lock file.";
	if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
		msg = [[error userInfo] objectForKey:@"error"];
	}
	[delegate database:self failedToRemoveLockWithReason:msg];
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath {
	if(mode == LOADING_DB_FILE){ // loading latest revision
		
		// update local metadata
		self.revision = tempMeta.revision;
        self.rev = tempMeta.rev;
		self.lastModified = [[tempMeta.lastModifiedDate copy] autorelease];
		self.lastSynced = [[NSDate new] autorelease];
		[tempMeta release];
		[dbManager updateDatabase:self];
		
		[delegate databaseUpdateComplete:self];
	}
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
	if(mode == LOADING_DB_FILE){ // loading latest revision
		[tempMeta release];
		NSString *msg = @"There was an error removing the lock file.";
		if(error != nil && [error userInfo] != nil && [[error userInfo] objectForKey:@"error"] != nil){
			msg = [[error userInfo] objectForKey:@"error"];
		}
		[delegate database:self updateFailedWithReason:msg];
	}
}

#pragma mark - utility stuff needs to be moved

- (NSDate*)parseDate:(uint8_t*)dtime {
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	int year = (dtime[0] << 6) | (dtime[1] >> 2);
	int mon = ((dtime[1] & 3) << 2) | (dtime[2] >> 6);
	int day = (dtime[2] & 63) >> 1;
	int hour = ((dtime[2] & 1) << 4) | (dtime[3] >> 4);
	int min = ((dtime[3] & 15) << 2) | (dtime[4] >> 6);
	int sec = dtime[4] & 63;
    
	[comps setYear:year];
	[comps setMonth:mon];
	[comps setDay:day];
	[comps setHour:hour];
	[comps setMinute:min];
	[comps setSecond:sec];
	
	NSDate *date = [gregorian dateFromComponents:comps];
	[comps release];
	[gregorian release];
	
	return date;
}

-(void)packDate:(NSDate *)date toBuffer:(uint8_t *)buffer{
    NSCalendar *cal = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents *com = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    int y = com.year, mon = com.month, d=com.day, h=com.hour, min=com.minute, s=com.second;
    buffer[0] = (uint8_t)(((uint32_t)y >> 6) & 0x0000003F);
    buffer[1] = (uint8_t)((((uint32_t)y & 0x0000003F) << 2) | (((uint32_t)mon >> 2) & 0x00000003));
    buffer[2] = (uint8_t)((((uint32_t)mon & 0x00000003) << 6) | (((uint32_t)d & 0x0000001F) << 1) | (((uint32_t)h >> 4) & 0x00000001));
    buffer[3] = (uint8_t)((((uint32_t)h & 0x0000000F) << 4) | (((uint32_t)min >> 2) & 0x0000000F));
    buffer[4] = (uint8_t)((((uint32_t)min & 0x00000003) << 6) | ((uint32_t)s & 0x0000003F));        
}

#pragma mark -
#pragma mark memory management

- (void)dealloc {
	[localPath release];
	[identifier release];
	[name release];
	[lastModified release];
	[lastSynced release];
	[lastError release];
	[restClient release];
    if(kpDatabase != NULL)
        kpass_free_db(kpDatabase);
    if(pwHash != NULL)
        free(pwHash);
	[super dealloc];
}

@end
