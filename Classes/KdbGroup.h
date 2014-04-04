//
//  KdbGroup.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kpass.h"
#import "Database.h"
#import "KdbEntry.h"

typedef struct kpass_entry_item kpass_entry_item;
typedef struct kpass_group_item kpass_group_item;

struct kpass_group_item {
    kpass_group *group;
    kpass_group_item *next;
};

struct kpass_entry_item {
    kpass_entry *entry;
    kpass_entry_item *next;
};

@interface KdbGroup : NSObject {
	kpass_group *kpGroup;
	BOOL isRoot;
	NSMutableArray *subGroups;
	NSMutableArray *entries;
	KdbGroup *parent;
	id<Database> database;
}

@property (nonatomic) BOOL isRoot;
@property (retain, nonatomic) NSMutableArray *subGroups;
@property (retain, nonatomic) NSMutableArray *entries;
@property (assign, nonatomic) KdbGroup *parent;
@property (assign, nonatomic) id<Database> database;

- (id)initForDatabase:(id<Database>)db;
- (id)initWithGroup:(kpass_group*)group forDatabase:(id<Database>)db;
- (id)initWithParent:(KdbGroup*)parentGroup withTitle:(NSString*)title withIcon:(uint32_t)icon forDatabase:(id<Database>)db;
- (id)initRootGroupWithCount:(int)subGroupCount subGroups:(kpass_group**)groups andCount:(int)entryCount groupEntries:(kpass_entry**)groupEntries forDatabase:(id<Database>)db;
- (kpass_group*)kpGroup;

- (void)updateWithParent:(KdbGroup*)parent withTitle:(NSString*)title withIcon:(uint32_t)icon;
- (void)moveSubGroupFromIndex:(int)fromIndex toIndex:(int)toIndex;
- (void)moveEntryFromIndex:(int)fromIndex toIndex:(int)toIndex;

- (void)deleteGroupAtIndex:(int)index;
- (void)deleteEntryAtIndex:(int)index;

- (NSString*)groupName;
- (UIImage*)groupIcon;

@end
