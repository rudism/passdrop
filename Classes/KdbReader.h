//
//  KdbReader.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kpass.h"
#import "KdbGroup.h"
#import "Database.h"

@interface KdbReader : NSObject {
	NSString *databaseFilePath;
	kpass_db *kpassDb;
	uint8_t *kpassPw;
	kpass_retval retval;
	NSString *lastError;
}

@property (retain, nonatomic) NSString *databaseFilePath;
@property (retain, nonatomic) NSString *lastError;

- (id) initWithKdbFile:(NSString*)filePath usingPassword:(NSString*)password;
- (KdbGroup*)getRootGroupForDatabase:(id<Database>)database;
- (BOOL)hasError;
- (kpass_db*)kpDatabase;

@end
