//
//  KdbWriter.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 8/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kpass.h"

@interface KdbWriter : NSObject {
    NSString *lastError;
    kpass_retval retval;
}

@property (copy, nonatomic) NSString* lastError;

- (BOOL) saveDatabase:(kpass_db*)database withPassword:(uint8_t*)pw toFile:(NSString*)path;

@end
