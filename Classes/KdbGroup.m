//
//  KdbGroup.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KdbGroup.h"


@implementation KdbGroup

@synthesize isRoot;
@synthesize subGroups;
@synthesize parent;
@synthesize entries;
@synthesize database;

- (id)initForDatabase:(id<Database>)db {
    if((self = [super init])){
        self.database = db;
        kpGroup = (kpass_group*)malloc(sizeof(kpass_group));
        self.subGroups = [[[NSMutableArray alloc] init] autorelease];
        self.entries = [[[NSMutableArray alloc] init] autorelease];
    }
    return self;
}

- (id)initWithGroup:(kpass_group*)group forDatabase:(id<Database>)db {
	if((self = [super init])){
		self.database = db;
		if(group != NULL){
			self.isRoot = NO;
			kpGroup = group;
			self.subGroups = [[[NSMutableArray alloc] init] autorelease];
			self.entries = [[[NSMutableArray alloc] init] autorelease];
		} else {
			self = nil;
		}
	}
	return self;
}

- (int)insertSubGroupsFrom:(KdbGroup*)group into:(kpass_group**)destination atIndex:(int)pos atLevel:(int)level {
    if([group.subGroups count] > 0){
        for(int i = 0; i < [group.subGroups count]; i++){
            KdbGroup *subGroup = [group.subGroups objectAtIndex:i];
            destination[pos++] = [subGroup kpGroup];
            [subGroup kpGroup]->level = level;
            pos = [self insertSubGroupsFrom:subGroup into:destination atIndex:pos atLevel:level+1];
        }
    } 
    return pos;
}

- (int)insertEntriesFrom:(KdbGroup*)group into:(kpass_entry**)destination atIndex:(int)pos {
    for(int i = 0; i < [group.entries count]; i++){
        KdbEntry *entry = [group.entries objectAtIndex:i];
        destination[pos++] = [entry kpEntry];
    }
    if([group.subGroups count] > 0){
        for(int i = 0; i < [group.subGroups count]; i++){
            KdbGroup *subGroup = [group.subGroups objectAtIndex:i];
            pos = [self insertEntriesFrom:subGroup into:destination atIndex:pos];
        }
    }
    return pos;
}

- (id)initWithParent:(KdbGroup*)parentGroup withTitle:(NSString*)title withIcon:(uint32_t)icon forDatabase:(id<Database>)db {
    if((self = [super init])){
        self.database = db;
        kpGroup = malloc(sizeof(kpass_group));
        kpGroup->id = [db nextGroupId];
        kpGroup->image_id = icon;
        kpGroup->name = malloc(sizeof(char) * [title length]+1);
        strcpy(kpGroup->name, [title cStringUsingEncoding:NSUTF8StringEncoding]);
        kpGroup->flags = 0;
        [db packDate:[NSDate date] toBuffer:kpGroup->ctime];
        [db packDate:[NSDate date] toBuffer:kpGroup->mtime];
        [db packDate:[NSDate date] toBuffer:kpGroup->atime];
        uint8_t never[5] = {0x2E, 0xDF, 0x39, 0x7E, 0xFB};
        memcpy(kpGroup->etime, never, 5);
        
        // update wrapper
        [parentGroup.subGroups addObject:self];
        self.parent = parentGroup;
        self.subGroups = [NSMutableArray array];
        self.entries = [NSMutableArray array];
        self.isRoot = NO;
        
        // update kp objects
        kpass_db *kpdb = [[parentGroup database] kpDatabase];
        kpass_group *group = NULL;
        kpass_group **newgroups = malloc(sizeof(*group) * kpdb->groups_len + 1);
        memset(newgroups, 0, sizeof(*group) * kpdb->groups_len + 1);
        
        kpdb->groups_len = [self insertSubGroupsFrom:[[parentGroup database] rootGroup] into:newgroups atIndex:0 atLevel:0];
        free(kpdb->groups);
        kpdb->groups = newgroups;
    } else {
        self = nil;
    }
    return self;
}

- (id)initRootGroupWithCount:(int)subGroupCount subGroups:(kpass_group**)groups andCount:(int)entryCount groupEntries:(kpass_entry**)groupEntries forDatabase:(id<Database>)db {
	NSMutableArray *tempGroups = [[NSMutableArray alloc] initWithCapacity:subGroupCount];
	NSMutableArray *levels = [[NSMutableArray alloc] initWithCapacity:subGroupCount];
	NSMutableDictionary *groupLookup = [[NSMutableDictionary alloc] initWithCapacity:subGroupCount];
	
	self.isRoot = YES;
	self.database = db;
	
	// create all the groups in temp array
	for(int i = 0; i < subGroupCount; i++){
		kpass_group *group = groups[i];
		KdbGroup *subGroup = [[[KdbGroup alloc] initWithGroup:group forDatabase:db] autorelease];
		[tempGroups addObject:subGroup];
		[levels addObject:[NSNumber numberWithInt:group->level]];
		[groupLookup setObject:subGroup forKey:[NSNumber numberWithInt:group->id]];
	}
	
	// build the group tree in our subGroups array
	self.subGroups = [[[NSMutableArray alloc] init] autorelease];
	
	for(int i = 0; i < subGroupCount; i++){
		int level = [(NSNumber*)[levels objectAtIndex:i] intValue];
		KdbGroup *subGroup = [tempGroups objectAtIndex:i];
		if(level == 0){
			subGroup.parent = self;
			[subGroups addObject:subGroup];
		} else {
			// find the most recent group in the list with a lower level, which is the parent
			for(int j = i; j >= 0; j--){
				int plevel = [(NSNumber*)[levels objectAtIndex:j] intValue];
				if(level > plevel){
					subGroup.parent = [tempGroups objectAtIndex:j];
					[[[tempGroups objectAtIndex:j] subGroups] addObject:subGroup];
					break;
				}
			}
		}
	}
	
	// add all of the entries to their parents
	self.entries = [[[NSMutableArray alloc] init] autorelease];
	
	for(int i = 0; i < entryCount; i++){
		kpass_entry *kpEntry = groupEntries[i];
		
		// filter out meta-info entries
		if(!(0 == strcmp("Meta-Info", kpEntry->title)
                    && 0 == strcmp("bin-stream", kpEntry->desc)
                    && 0 == strcmp("SYSTEM", kpEntry->username)
                    && 0 == strcmp("$", kpEntry->url)
					   /*== kpEntry->image_id*/)){
			KdbEntry *entry = [[[KdbEntry alloc] initWithEntry:kpEntry] autorelease];
            entry.database = db;
			NSNumber *parentId = [NSNumber numberWithInt:kpEntry->group_id];
			KdbGroup *parentGroup = [groupLookup objectForKey:parentId];
			entry.parent = parentGroup;
			[parentGroup.entries addObject:entry];
		}
	}
	
	// release temporary vars
	while([tempGroups count] > 0){
		[tempGroups removeObjectAtIndex:0];
	}
	[levels release];
	[groupLookup removeAllObjects];
	[groupLookup release];
	[tempGroups release];
	
	return self;
}

- (kpass_group*)kpGroup {
    return kpGroup;
}

- (NSString*)groupName {
	return [NSString stringWithCString:kpGroup->name encoding:NSUTF8StringEncoding];
}

- (UIImage*)groupIcon {
    if(kpGroup->image_id <= 68)
        return [UIImage imageNamed:[NSString stringWithFormat:@"%d.png", kpGroup->image_id]];
    return [UIImage imageNamed:@"0.png"];
}

- (void)updateWithParent:(KdbGroup*)parentGroup withTitle:(NSString*)title withIcon:(uint32_t)icon {
    // update db structures
    if(kpGroup->name) {
		memset(kpGroup->name, 0, strlen(kpGroup->name));
		free(kpGroup->name);
	}
    kpGroup->name = malloc(sizeof(char) * [title length]+1);
    strcpy(kpGroup->name, [title cStringUsingEncoding:NSUTF8StringEncoding]);
    
    kpGroup->image_id = icon;
    [database packDate:[NSDate date] toBuffer:kpGroup->mtime];
    [database packDate:[NSDate date] toBuffer:kpGroup->atime];
    
    // reassign to new parent if it changed
    if(self.parent != parentGroup){
        // update wrapper classes
        [parent.subGroups removeObject:self];
        [parentGroup.subGroups addObject:self];

        // create new container for group structure
        kpass_db *kpdb = [[parentGroup database] kpDatabase];
        kpass_group *group = NULL;
        kpass_group **newgroups = malloc(sizeof(*group) * kpdb->groups_len);
        memset(newgroups, 0, sizeof(*group) * kpdb->groups_len);
        
        [self insertSubGroupsFrom:[[parentGroup database] rootGroup] into:newgroups atIndex:0 atLevel:0];
        free(kpdb->groups);
        kpdb->groups = newgroups;
        
        self.parent = parentGroup;
    }
}

- (void)moveSubGroupFromIndex:(int)fromIndex toIndex:(int)toIndex {
    // update wrapper structure
    KdbGroup *movingGroup = [[self.subGroups objectAtIndex:fromIndex] retain];
    [self.subGroups removeObject:movingGroup];
    if(toIndex >= self.subGroups.count){
        [self.subGroups addObject:movingGroup];
    } else {
        [self.subGroups insertObject:movingGroup atIndex:toIndex];
    }
    
    // update group structure
    kpass_db *kpdb = [database kpDatabase];
    kpass_group *group = NULL;
    kpass_group **newgroups = malloc(sizeof(*group) * kpdb->groups_len);
    memset(newgroups, 0, sizeof(*group) * kpdb->groups_len);
    
    [self insertSubGroupsFrom:[database rootGroup] into:newgroups atIndex:0 atLevel:0];
    free(kpdb->groups);
    kpdb->groups = newgroups;
    [movingGroup release];
}

- (void)moveEntryFromIndex:(int)fromIndex toIndex:(int)toIndex {
    // update wrapper structure
    KdbEntry *movingEntry = [[self.entries objectAtIndex:fromIndex] retain];
    [self.entries removeObject:movingEntry];
    if(toIndex >= self.entries.count){
        [self.entries addObject:movingEntry];
    } else {
        [self.entries insertObject:movingEntry atIndex:toIndex];
    }
    
    // update group structure
    kpass_db *kpdb = [database kpDatabase];
    kpass_entry *entry = NULL;
    kpass_entry **newentries = malloc(sizeof(*entry) * kpdb->entries_len);
    memset(newentries, 0, sizeof(*entry) * kpdb->entries_len);
    
    int lastpos = [self insertEntriesFrom:[database rootGroup] into:newentries atIndex:0];
    int pos = lastpos;
    
    if(lastpos < kpdb->entries_len){
        //add any hidden/metadata entries
        for(int i = 0; i < kpdb->entries_len; i++){
            BOOL added = NO;
            for(int j = 0; j < lastpos; j++){
                if(newentries[j] == kpdb->entries[i]){
                    added = YES;
                    break;
                }
            }
            if(added) continue;
            newentries[pos++] = kpdb->entries[i];
        }
    }
    
    free(kpdb->entries);
    kpdb->entries = newentries;
    [movingEntry release];
}

- (int*)getEntityCountsFromGroup:(KdbGroup*)group groupList:(kpass_group_item*)groupList entryList:(struct kpass_entry_item*)entryList {
    int *delCount = malloc(sizeof(int)*2);
    delCount[0] = delCount[1] = 0;
    
    kpass_group_item *gcursor = groupList;
    kpass_entry_item *ecursor = entryList;

    gcursor->group = [group kpGroup];
    gcursor->next = malloc(sizeof(kpass_group_item));
    gcursor = gcursor->next;
    gcursor->group = NULL;
    gcursor->next = NULL;
    
    delCount[0]++;
    
    for(int i = 0; i < group.entries.count; i++){
        ecursor->entry = ((KdbEntry*)[group.entries objectAtIndex:i]).kpEntry;
        ecursor->next = malloc(sizeof(kpass_entry_item));
        ecursor = ecursor->next;
        ecursor->entry = NULL;
        ecursor->next = NULL;
        
        delCount[1]++;
    }
    
    for(int i = 0; i < group.subGroups.count; i++){
        int* newCount = [self getEntityCountsFromGroup:[group.subGroups objectAtIndex:i] groupList:gcursor entryList:ecursor];
        while(gcursor->next != NULL){
            gcursor = gcursor->next;
        }
        while(ecursor->next != NULL){
            ecursor = ecursor->next;
        }
        delCount[0] += newCount[0];
        delCount[1] += newCount[1];
    }
    
    return delCount;
}

- (void)deleteGroupAtIndex:(int)index{
    KdbGroup *deleting = [[self.subGroups objectAtIndex:index] retain];
    
    struct kpass_group_item *groupList = malloc(sizeof(kpass_group_item));
    struct kpass_entry_item *entryList = malloc(sizeof(kpass_entry_item));
    
    groupList->group = NULL;
    groupList->next = NULL;
    entryList->entry = NULL;
    entryList->next = NULL;
    
    int *delCount = [self getEntityCountsFromGroup:deleting groupList:groupList entryList:entryList];
    int pos;
    
    kpass_db *kpdb = [database kpDatabase];
    
    kpass_group *group = NULL;
    kpass_group **newgroups = malloc(sizeof(*group) * (kpdb->groups_len-delCount[0]));
    memset(newgroups, 0, sizeof(*group) * (kpdb->groups_len-delCount[0]));
    
    pos = 0;
    for(int i = 0; i < kpdb->groups_len; i++){
        kpass_group_item *gcursor = groupList;
        BOOL found = NO;
        while(gcursor->group != NULL){
            if(gcursor->group == kpdb->groups[i]){
                found = YES;
                break;
            }
            gcursor = gcursor->next;
        }
        if(found) continue;
        newgroups[pos++] = kpdb->groups[i];
    }
    
    kpass_entry *entry = NULL;
    kpass_entry **newentries = malloc(sizeof(*entry) * (kpdb->entries_len-delCount[1]));
    memset(newentries, 0, sizeof(*entry) * (kpdb->entries_len-delCount[1]));
    
    pos = 0;
    for(int i = 0; i < kpdb->entries_len; i++){
        kpass_entry_item *ecursor = entryList;
        BOOL found = NO;
        while(ecursor->entry != NULL){
            if(ecursor->entry == kpdb->entries[i]){
                found = YES;
                break;
            }
            ecursor = ecursor->next;
        }
        if(found) continue;
        newentries[pos++] = kpdb->entries[i];
    }
    
    [self.subGroups removeObject:deleting];
    kpass_free_group([deleting kpGroup]);
    [deleting release];
    
    free(kpdb->groups);
    kpdb->groups_len-=delCount[0];
    kpdb->groups = newgroups;
    
    free(kpdb->entries);
    kpdb->entries_len-=delCount[1];
    kpdb->entries = newentries;
}

- (void)deleteEntryAtIndex:(int)index{
    KdbEntry *deleting = [[self.entries objectAtIndex:index] retain];
    
    kpass_db *kpdb = [database kpDatabase];
    kpass_entry *entry = NULL;
    kpass_entry **newentries = malloc(sizeof(*entry) * (kpdb->entries_len-1));
    memset(newentries, 0, sizeof(*entry) * (kpdb->entries_len-1));
    
    int pos = 0;
    for(int i = 0; i < kpdb->entries_len; i++){
        if(kpdb->entries[i] != [deleting kpEntry]){
            newentries[pos++] = kpdb->entries[i];
        }
    }
    
    [self.entries removeObject:deleting];
    kpass_free_entry([deleting kpEntry]);
    [deleting release];

    free(kpdb->entries);
    kpdb->entries = newentries;
    kpdb->entries_len--;
}

- (void) dealloc {
	while([subGroups count] > 0){
		[subGroups removeObjectAtIndex:0];
	}
	[subGroups release];
	while([entries count] > 0){
		[entries removeObjectAtIndex:0];
	}
	[entries release];
	[super dealloc];
}

@end
