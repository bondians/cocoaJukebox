//
//  UserPlayList.h
//  cocoaJukebox
//
//  Created by David Henderson on 10/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UserPlayList : NSObject
{
    NSString *userName;
	NSMutableArray *userList;
	NSMutableArray *listCounts;
	IBOutlet NSTableView *myTableView;

}

- (id) init;
+ (id) playListWithList:(NSDictionary *) list;
- (int) numberOfRowsInTableView: (NSTableView *) aTableView;

- (id)tableView: (NSTableView *) aTableView
		objectValueForTableColumn: (NSTableColumn *) aTableColumn
		row: (int) rowIndex;
- (id) objectForIndex: (int) index;
- (int) countForIndex: (int)index;

@end
