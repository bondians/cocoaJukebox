//
//  UserPlayList.m
//  cocoaJukebox
//
//  Created by David Henderson on 10/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "UserPlayList.h"


@implementation UserPlayList

- (id) init
{
    if (![super init])
        return nil;
	userList = [[NSMutableArray alloc] init];
	listCounts = [[NSMutableArray alloc] init];

    
    return self;
}

- (id)initWithUserList:(NSDictionary *) list
{
	[self init];
	[userList addObjectsFromArray: [list objectForKey: @"lists"]];
	[listCounts addObjectsFromArray: [list objectForKey: @"lengths"]];
	[myTableView reloadData];
	return self;
}

+ (id) playListWithList:(NSDictionary *) list
{
	return [[[self alloc] initWithUserList: list] autorelease];
}

- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [userList count];
}

- (id) tableView: (NSTableView *) aTableView
		objectValueForTableColumn: (NSTableColumn *) aTableColumn
		row: (int) rowIndex
{
	if ([[aTableColumn identifier] isEqual: @"playLists"])
		return [userList objectAtIndex: rowIndex];

	if ([[aTableColumn identifier] isEqual: @"entries"])
		return [listCounts objectAtIndex: rowIndex];

	return nil;
}

- (id) objectForIndex: (int) index
{
	return [userList objectAtIndex: index];
}

- (int) countForIndex: (int) index
{
	return [[listCounts objectAtIndex: index] intValue];
}

@end
