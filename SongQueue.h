//
//  RandomList.h
//  cocoaJukebox
//
//  Created by David Henderson on 9/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArrayAdditions.h"
#import "SQInterface.h"
#import "DBSong.h"

#define MAX_RANDOM_QUEUE_SIZE 20
#define kRandomQueueLength MIN([randomList count], MAX_RANDOM_QUEUE_SIZE)

enum queueType {
    kRequestQueue = 0,
	kRandomQueue = 1
};

@interface SongQueue : NSObject
{
	id _delegate;
	NSMutableArray *randomList;
	NSMutableArray *randomQueue;
	NSMutableArray *requestQueue;
	NSLock *randomListLock;
	NSLock *randomQueueLock;
	NSLock *requestQueueLock;
	SQInterface *myConnection;
	
	NSUserDefaultsController *defaultsController;
	BOOL respectSongHinting;
	DBSong *followOnSong;
	
	IBOutlet NSProgressIndicator *playListLoader;

}

- (id) init;
- (id) delegate;
- (void) setDelegate:(id)new_delegate;
- (void) dumpRandomList;
- (void) setRandomList: (NSArray *) userList;
- (void) setRandomListThread: (NSArray *) userList;
- (int) randomListCount;
- (int) randomQueueCount;
- (int) requestQueueCount;
- (void) setProgressIndicator: (NSProgressIndicator *) indicator;
- (NSArray *) randomList;
- (NSArray *) randomQueue;
- (DBSong *) getNextRandom;
- (DBSong *) getNextRequest;
- (DBSong *) getNextSong;
- (void) dumpRequestQueueAndAddSongsInArray: (NSArray *) theSongs;
- (void) topOfRequestQueueForSong: (DBSong *) aSong;
- (void) topOfRequestQueueForSongsInArray: (NSArray *) theSongs;
- (void) removeSongFromRequestQueue: (DBSong *) aSong;
- (void) removeSongFromRandomQueue: (DBSong *) aSong;
- (void) removeSongFromQueues: (DBSong *) aSong; 
- (void) removeSongFromRandomList: (DBSong *) aSong;
- (void) requestSong: (DBSong *) theSong;
- (void) requestSongForKey: (NSString *) archiveKey;
- (BOOL) requestSongWithData: (NSData *) archivedSong;
- (BOOL) dequeueSongForKey: (NSString *) key fromQueue: (int) queueNum;
- (BOOL) queueSongForKey: (NSString *) key position: (unsigned) position inQueue: (int) queueNum;
- (void) copyRequestData: (NSMutableData*) data;
- (NSArray *) dbKeysFromQueue: (int) queueNum;
- (void) refreshRandomQueue;
- (void) refreshRandomQueueThread;
- (void) dumpRequestQueue;
- (void) dumpRandomQueueShouldReload: (BOOL) reload;
	// delegate methods used to control the player
- (void) pauseSong;
- (void) skipSong;

@end

@interface NSObject (CDCOurClassDelegate)

- (void) pause;
- (void) skipSong;

@end

