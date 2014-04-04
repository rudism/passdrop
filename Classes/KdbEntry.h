//
//  KdbEntry.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kpass.h"
#import "Database.h"
#import "KdbEntry.h"
#import "KdbGroup.h"

@interface KdbEntry : NSObject {
	kpass_entry *kpEntry;
	KdbGroup *parent;
	id<Database> database;
}

@property (assign, nonatomic) KdbGroup *parent;
@property (assign, nonatomic) id<Database> database;

- (id)initWithEntry:(kpass_entry*)entry;
- (id)initWithParent:(KdbGroup*)parentGroup withTitle:(NSString*)title withIcon:(uint32_t)icon withUsername:(NSString*)username withPassword:(NSString*)password withUrl:(NSString*)url withNotes:(NSString*)notes withExpires:(NSDate*)expires forDatabase:(id<Database>)db;
- (void)updateWithParent:(KdbGroup*)parentGroup withTitle:(NSString*)title withIcon:(uint32_t)icon withUsername:(NSString*)username withPassword:(NSString*)password withUrl:(NSString*)url withNotes:(NSString*)notes withExpires:(NSDate*)expires;

- (NSString*)entryName;
- (UIImage*)entryIcon;
- (NSString*)entryUrl;
- (NSString*)entryUsername;
- (NSString*)entryPassword;
- (NSString*)entryNotes;

- (NSDate*)createdDate;
- (NSDate*)modifiedDate;
- (NSDate*)accessDate;
- (NSDate*)expireDate;

- (kpass_entry*) kpEntry;

// todo: attachment stuff

@end
