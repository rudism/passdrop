//
//  KdbReader.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KdbReader.h"


@implementation KdbReader

@synthesize databaseFilePath;
@synthesize lastError;

- (id) initWithKdbFile:(NSString*)filePath usingPassword:(NSString*)password {
	lastError = nil;
	if((self = [super init])){
		// load database from file
		self.databaseFilePath = [NSString stringWithString:filePath];
		NSData *dbData = [NSData dataWithContentsOfFile:filePath];
		int length = [dbData length];
		const void *bytes = [dbData bytes];
		uint8_t *data = (uint8_t*)bytes;
		kpassDb = malloc(sizeof(kpass_db));

		// read encrypted database
		retval = kpass_init_db(kpassDb, data, length);
		if(retval != kpass_success){
			self.lastError = @"There was an error loading the database.";
		} else {		
			// hash the password
			kpassPw = malloc(sizeof(uint8_t)*32);
			const char *cPw = [password cStringUsingEncoding:NSUTF8StringEncoding];
			retval = kpass_hash_pw(kpassDb, cPw, kpassPw);
			if(retval != kpass_success){
				self.lastError = @"There was an error with that password.";
			} else {
				// perform initial decryption
				retval = kpass_decrypt_db(kpassDb, kpassPw);
				if(retval != kpass_success){
					self.lastError = @"Could not decrypt the database. Please verify your password.";
				}
			}
		}
	}
	return self;
}

- (BOOL)hasError {
	return retval != kpass_success;
}

- (KdbGroup*)getRootGroupForDatabase:(id<Database>)database {
    [database setKpDatabase:kpassDb];
    [database setPwHash:kpassPw];
	return [[[KdbGroup alloc] initRootGroupWithCount:kpassDb->groups_len subGroups:kpassDb->groups andCount:kpassDb->entries_len groupEntries:kpassDb->entries forDatabase:database] autorelease];
}

- (kpass_db*)kpDatabase {
    return kpassDb;
}

- (void) dealloc {
	[lastError release];
	[databaseFilePath release];
	[super dealloc];
}

@end
