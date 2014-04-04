//
//  KdbEntry.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KdbEntry.h"


@implementation KdbEntry

@synthesize parent;
@synthesize database;

- (id)initWithEntry:(kpass_entry*)entry {
	if((self = [super init])){
		kpEntry = entry;
	}
	return self;
}

- (id)initWithParent:(KdbGroup*)parentGroup withTitle:(NSString*)title withIcon:(uint32_t)icon withUsername:(NSString*)username withPassword:(NSString*)password withUrl:(NSString*)url withNotes:(NSString*)notes withExpires:(NSDate*)expires forDatabase:(id<Database>)db {
    if((self = [super init])){
        self.database = db;
        kpEntry = malloc(sizeof(kpass_entry));
        kpEntry->group_id = [parentGroup kpGroup]->id;
        
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
        CFRelease(uuid);
        memcpy(kpEntry->uuid, &uuidBytes, 16);
        
        kpEntry->image_id = icon;
        kpEntry->title = malloc(sizeof(char) * [title length]+1);
        strcpy(kpEntry->title, [title cStringUsingEncoding:NSUTF8StringEncoding]);
        kpEntry->username = malloc(sizeof(char) * [username length]+1);
        strcpy(kpEntry->username, [username cStringUsingEncoding:NSUTF8StringEncoding]);
        kpEntry->password = malloc(sizeof(char) * [password length]+1);
        strcpy(kpEntry->password, [password cStringUsingEncoding:NSUTF8StringEncoding]);
        kpEntry->url = malloc(sizeof(char) * [url length]+1);
        strcpy(kpEntry->url, [url cStringUsingEncoding:NSUTF8StringEncoding]);
        kpEntry->notes = malloc(sizeof(char) * [notes length]+1);
        strcpy(kpEntry->notes, [notes cStringUsingEncoding:NSUTF8StringEncoding]);
        kpEntry->desc = malloc(1);
        memset(kpEntry->desc, 0, 1);
        kpEntry->data_len = 0;
        kpEntry->data = NULL;
        
        [db packDate:[NSDate date] toBuffer:kpEntry->ctime];
        [db packDate:[NSDate date] toBuffer:kpEntry->mtime];
        [db packDate:[NSDate date] toBuffer:kpEntry->atime];
        
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:expires];
        if([comps year] == 2999){
            uint8_t never[5] = {0x2E, 0xDF, 0x39, 0x7E, 0xFB};
            memcpy(kpEntry->etime, never, 5);
        } else {
            [db packDate:expires toBuffer:kpEntry->etime];
        }
        
        // update wrapper
        [parentGroup.entries addObject:self];
        self.parent = parentGroup;
        
        // update kp objects
        kpass_db *kpdb = [[parentGroup database] kpDatabase];
        kpass_entry *entry = NULL;
        kpass_entry **newentries = malloc(sizeof(*entry) * kpdb->entries_len + 1);
        memset(newentries, 0, sizeof(*entry) * kpdb->entries_len + 1);
        
        for(int i = 0; i < kpdb->entries_len; i++){
            newentries[i] = kpdb->entries[i];
        }
        newentries[kpdb->entries_len] = kpEntry;
        
        kpdb->entries_len++;
        free(kpdb->entries);
        kpdb->entries = newentries;
    } else {
        self = nil;
    }
    return self;
}

- (kpass_entry*)kpEntry {
    return kpEntry;
}

- (NSString*)entryName {
	return [NSString stringWithCString:kpEntry->title encoding:NSUTF8StringEncoding];
}

- (UIImage*)entryIcon {
	if(kpEntry->image_id <= 68){
		return [UIImage imageNamed:[NSString stringWithFormat:@"%d.png", kpEntry->image_id]];
	}
	return [UIImage imageNamed:@"0.png"];
}

- (NSString*)entryUrl {
	return [NSString stringWithCString:kpEntry->url encoding:NSUTF8StringEncoding];
}

- (NSString*)entryUsername {
	return [NSString stringWithCString:kpEntry->username encoding:NSUTF8StringEncoding];
}

- (NSString*)entryPassword {
	return [NSString stringWithCString:kpEntry->password encoding:NSUTF8StringEncoding];
}

- (NSString*)entryNotes {
	return [NSString stringWithCString:kpEntry->notes encoding:NSUTF8StringEncoding];
}

- (NSDate*)createdDate {
	return [database parseDate:kpEntry->ctime];
}

- (NSDate*)modifiedDate {
	return [database parseDate:kpEntry->mtime];
}

- (NSDate*)accessDate {
	return [database parseDate:kpEntry->atime];
}

- (NSDate*)expireDate {
	return [database parseDate:kpEntry->etime];
}

- (void)updateWithParent:(KdbGroup*)parentGroup withTitle:(NSString*)title withIcon:(uint32_t)icon withUsername:(NSString*)username withPassword:(NSString*)password withUrl:(NSString*)url withNotes:(NSString*)notes withExpires:(NSDate*)expires {
    // update db structures
    if(kpEntry->title) {
		memset(kpEntry->title, 0, strlen(kpEntry->title));
		free(kpEntry->title);
	}
    kpEntry->title = malloc(sizeof(char) * [title length]+1);
    strcpy(kpEntry->title, [title cStringUsingEncoding:NSUTF8StringEncoding]);
    
    kpEntry->image_id = icon;
    [database packDate:[NSDate date] toBuffer:kpEntry->mtime];
    
    if(kpEntry->username) {
		memset(kpEntry->username, 0, strlen(kpEntry->username));
		free(kpEntry->username);
	}
    kpEntry->username = malloc(sizeof(char) * [username length]+1);
    strcpy(kpEntry->username, [username cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if(password != nil){
        if(kpEntry->password) {
            memset(kpEntry->password, 0, strlen(kpEntry->password));
            free(kpEntry->password);
        }
        kpEntry->password = malloc(sizeof(char) * [password length]+1);
        strcpy(kpEntry->password, [password cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    if(kpEntry->url) {
		memset(kpEntry->url, 0, strlen(kpEntry->url));
		free(kpEntry->url);
	}
    kpEntry->url = malloc(sizeof(char) * [url length]+1);
    strcpy(kpEntry->url, [url cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if(kpEntry->notes) {
		memset(kpEntry->notes, 0, strlen(kpEntry->notes));
		free(kpEntry->notes);
	}
    kpEntry->notes = malloc(sizeof(char) * [notes length]+1);
    strcpy(kpEntry->notes, [notes cStringUsingEncoding:NSUTF8StringEncoding]);
    
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:expires];
    if([comps year] == 2999){
        uint8_t never[5] = {0x2E, 0xDF, 0x39, 0x7E, 0xFB};
        memcpy(kpEntry->etime, never, 5);
    } else {
        [self.database packDate:expires toBuffer:kpEntry->etime];
    }
    
    [self.database packDate:[NSDate date] toBuffer:kpEntry->atime];
    [self.database packDate:[NSDate date] toBuffer:kpEntry->mtime];
    
    // reassign to new parent if it changed
    if(self.parent != parentGroup){
        kpEntry->group_id = [parentGroup kpGroup]->id;
        // update wrapper classes
        [parent.entries removeObject:self];
        [parentGroup.entries addObject:self];
        self.parent = parentGroup;
    }
}

- (void)dealloc {
	[super dealloc];
}

@end
