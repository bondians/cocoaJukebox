//
//  SQInterface.h
//  cocoaJukebox
//
//  Created by David Henderson on 12/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sqlite3.h>

#import "DBSong.h"


@interface SQInterface : NSObject {
	sqlite3 *db;
	NSString *tPathToArchive;
	char *zErrMsg;
}

- (id) init;
- (DBSong *) getSongForKey: (NSString *) key;
- (NSMutableArray *) getSongListForUsers: (NSArray *) users;
- (NSMutableArray *) getSongListForKeys: (NSArray *) keys;
- (NSDictionary *) getUserSongLists;

- (void) disconnect;
- (void) dealloc;
@end
