//
//  KdbWriter.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 8/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KdbWriter.h"


@implementation KdbWriter

@synthesize lastError;

- (BOOL)saveDatabase:(kpass_db *)database withPassword:(uint8_t*)pw toFile:(NSString *)path {
    int size = kpass_db_encrypted_len(database);
    uint8_t *buf = malloc(sizeof(uint8_t) * size);
    BOOL success = NO;
    retval = kpass_encrypt_db(database, pw, buf);
    if(retval == kpass_success){
        NSData *content = [NSData dataWithBytes:buf length:size];
        [content writeToFile:path atomically:NO];
        success = YES;
    } else {
        self.lastError = @"There was an error encrypting the database.";
    }
    free(buf);
    return success;
}

-(void)dealloc {
    [lastError release];
    [super dealloc];
}

@end
