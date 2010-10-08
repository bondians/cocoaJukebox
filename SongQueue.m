//
//  RandomList.m
//  cocoaJukebox
//
//  Created by David Henderson on 9/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SongQueue.h"
#import "SQInterface.h"



@implementation SongQueue

- (id) init {
    if (![super init])
        return nil;
	
	randomList = [[NSMutableArray alloc] init];
	randomQueue = [[NSMutableArray alloc] init];
	requestQueue = [[NSMutableArray alloc] init];
	requestQueueLock = [[NSLock alloc] init];
	randomListLock = [[NSLock alloc] init];
	randomQueueLock = [[NSLock alloc] init];
	playListLoader = nil;
	followOnSong = nil;
	
		
	defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[self bind: @"respectSongHinting" toObject: defaultsController
	withKeyPath: @"values.kRespectSongHinting" options:nil];
	
	srandomdev();
	
	myConnection = [[SQInterface alloc] init];

    return self;
}

- (void) dumpRandomList
{
	[randomListLock lock];
	[randomList removeAllObjects];
	[randomListLock unlock];
}

- (void) setProgressIndicator: (NSProgressIndicator *) indicator
{
	playListLoader = indicator;
}

- (void) setRandomList: (NSArray *) userList
{
	[NSThread detachNewThreadSelector: @selector(setRandomListThread:)
							 toTarget: self withObject: userList];
}

- (void) setRandomListThread: (NSArray *) userList
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[randomListLock lock];
	if (playListLoader)
		[playListLoader startAnimation: nil];
	
	[randomList addObjectsFromArray: [myConnection getSongListForUsers: userList]];
	if (playListLoader)
		[playListLoader stopAnimation: nil];
	
	[randomListLock unlock];
	[self refreshRandomQueue];

	[pool release];
}

- (void) copyRequestData: (NSMutableData*) data
{
	DBSong *aSong;
	
	aSong = [NSUnarchiver unarchiveObjectWithData: data];
	[self requestSong: aSong];
}

- (NSArray *) dbKeysFromQueue: (int) queueNum
{
	NSArray *foo = nil;

    switch (queueNum) {
        case kRandomQueue:
            [randomQueueLock lock];
            foo = [randomQueue valueForKey: @"key"];
            [randomQueueLock unlock];
            break;

        case kRequestQueue:
            [requestQueueLock lock];
            foo = [requestQueue valueForKey: @"key"];
            [requestQueueLock unlock];
            break;

    }

    return foo;
}

- (void) requestSong: (DBSong *) theSong
{
	if (theSong) {
		[[theSong retain]autorelease];
		if ([theSong key]) {
			[randomQueueLock lock];
			[randomQueue removeObject: theSong];
			[randomQueueLock unlock];
			
			[requestQueueLock lock];
			[requestQueue removeObject: theSong];
			[requestQueue addObject: theSong];
			[requestQueueLock unlock];
		}
	}
}

- (void) requestSongForKey: (NSString *) archiveKey
{
	[self requestSong: [myConnection getSongForKey: archiveKey]];
}

- (BOOL) requestSongWithData: (NSData *) archivedSong
{
	DBSong *theSong;
	
	theSong = [[[NSKeyedUnarchiver unarchiveObjectWithData: archivedSong] retain] autorelease];
	if (theSong) {
		[self requestSong: theSong];
		return YES;
	}

	return NO;
}

- (BOOL) dequeueSongForKey: (NSString *) key fromQueue: (int) queueNum
{
	id dump;
	BOOL status = NO;
	
	switch (queueNum) {
        case kRandomQueue:
            [randomQueueLock lock];
			dump = [randomQueue objectForKey: @"key" value: key];
			if (dump) {
				[randomQueue removeObject: dump];
                status = YES;
            }
            [randomQueueLock unlock];
			[self refreshRandomQueue];
            break;
			
        case kRequestQueue:
            [requestQueueLock lock];
			dump = [requestQueue objectForKey: @"key" value: key];
			if (dump) {
				[requestQueue removeObject: dump];
                status = YES;
            }
			[requestQueueLock unlock];
            break;
    }

    return status;
}

- (BOOL) queueSongForKey: (NSString *) key position: (unsigned) position inQueue: (int) queueNum
{
    bool status = YES;
    DBSong *theSong = nil;

    [randomQueueLock lock];
    [requestQueueLock lock];

    // Remove song from queue(s) if it is already present

    // Look for key in request queue

    theSong = [[[requestQueue objectForKey: @"key" value: key] retain] autorelease];
    if (theSong) {
        [randomQueue removeObject: theSong];
        [requestQueue removeObject: theSong];
    }

    // Not found in request queue, look in random queue

    else {
        theSong = [[[randomQueue objectForKey: @"key" value: key] retain] autorelease];
        if (theSong) {
            [randomQueue removeObject: theSong];
        }

        // Key does not exist in either queue, so create a new entry

        else {
            theSong = [myConnection getSongForKey: key];
            if (!theSong) {
                status = NO;
            }
        }
    }

    // Insert song into appropriate queue at specified position

    if (status) {
       	switch (queueNum) {
            case kRequestQueue:
                if (![requestQueue count] <= position)
                    [requestQueue insertObject: theSong atIndex: position];
                else
                    [requestQueue addObject: theSong];
                break;

            case kRandomQueue:
                if (![randomQueue count] <= position)
                    [randomQueue insertObject: theSong atIndex: position];
                else
                    [requestQueue addObject: theSong];
                break;
        }
    }

    [requestQueueLock unlock];
    [randomQueueLock unlock];

    return status;
}

- (NSArray *) randomList
{
	return randomList;	
}

- (NSArray *) randomQueue
{
	NSArray *rQueue;
	
	[randomQueueLock lock];
	rQueue = [[randomQueue copy] autorelease];
	[randomQueueLock unlock];
	
	return rQueue;
}

- (DBSong *) getNextSong
{
	DBSong *aSong;
	NSString *preQueue;
	NSString *postQueue;
	
	if (respectSongHinting && followOnSong) {
		aSong = followOnSong;
		followOnSong = nil;
		return [aSong autorelease];
		}
	if (!respectSongHinting && followOnSong){
		[followOnSong release];
		followOnSong = nil;
		}

	aSong = [[[self getNextRequest] retain] autorelease];
	if (! aSong)
		aSong = [[[self getNextRandom] retain] autorelease];
	
	if (respectSongHinting){
	preQueue = [aSong preQueueKey];
	postQueue = [aSong postQueueKey];

	if ([preQueue intValue] > 1000) {
		followOnSong = [aSong retain];
		aSong = [[[myConnection getSongForKey: preQueue] retain] autorelease];
	} else {
		if ([postQueue intValue] > 1000) {
			followOnSong = [[myConnection getSongForKey: postQueue] retain];
		}
	}
}
	return aSong;
}

- (DBSong *) getNextRequest
{
	id obj = nil;

	[requestQueueLock lock];
	
	if ([requestQueue count] >= 1 )
		obj = [requestQueue popFirstObject];
	
	[requestQueueLock unlock];

	return obj;
}

- (DBSong *) getNextRandom
{
	id obj = nil;
	
	[randomQueueLock lock];

	if ([randomQueue count] >= 1 )
		obj = [randomQueue popFirstObject];
	
	[randomQueueLock unlock];

	return obj;
}

- (void) refreshRandomQueue
{
	[NSThread detachNewThreadSelector: @selector(refreshRandomQueueThread)
							 toTarget: self withObject: nil];
}

- (void) refreshRandomQueueThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	long selection;
	NSString *key;
	
	[randomListLock lock];
	[randomQueueLock lock];

	while([randomQueue count] < kRandomQueueLength) {
		selection = (random() %[randomList count]);
		key = [randomList objectAtIndex: selection];
		if(![randomQueue containsObjectForKey: @"key" value: key])
			[randomQueue addObject: [myConnection getSongForKey: key]];
	}

	[randomQueueLock unlock];
	[randomListLock unlock];
	[pool release];
}

- (void) dumpRequestQueue
{
	[requestQueueLock lock];
	[requestQueue removeAllObjects];
	[requestQueueLock unlock];
}

- (void) dumpRandomQueueShouldReload: (BOOL) reload
{
	[randomQueueLock lock];
	[randomQueue removeAllObjects];

	if (reload == YES) {
		[randomQueueLock unlock];
		[self refreshRandomQueue];
	}

	[randomQueueLock unlock];
}

- (int) randomListCount
{
	return [randomList count];
}

- (int) randomQueueCount
{
	return [randomQueue count];
}

- (int) requestQueueCount
{
	return [requestQueue count];
}

- (void) dumpRequestQueueAndAddSongsInArray: (NSArray *) theSongs
{
	
}

- (void) topOfRequestQueueForSong: (DBSong *) theSong
{
	
}

- (void) topOfRequestQueueForSongsInArray: (NSArray *) theSongs
{
	int i;

	if ([theSongs count] > 1) {
		NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndex: 0];
		for (i = 1; i < [theSongs count]; i++) {
			[indexes addIndex: i];
		}
		[randomQueueLock lock];
		[randomQueue removeObjectsInArray: theSongs];
		[randomQueueLock unlock];
		[requestQueueLock lock];
		[requestQueue removeObjectsInArray: theSongs];
		[requestQueue insertObjects: theSongs atIndexes: indexes];
		[requestQueueLock unlock];		
	}
}

- (void) removeSongFromQueues: (DBSong *) aSong
{
	[self removeSongFromRequestQueue: aSong];
	[self removeSongFromRandomQueue: aSong];
}

- (void) removeSongFromRequestQueue: (DBSong *) aSong
{
	[requestQueueLock lock];
	[requestQueue removeObject: aSong];
	[requestQueueLock unlock];
}

- (void) removeSongFromRandomQueue: (DBSong *) aSong
{
	[randomQueueLock lock];
	[randomQueue removeObject: aSong];
	[randomQueueLock unlock];
}

- (void) removeSongFromRandomList: (DBSong *) aSong
{
	[randomListLock lock];
	[randomList removeObject: aSong];
	[randomListLock unlock];
}

- (void) dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
    if (_delegate)
        [nc removeObserver:_delegate name:nil object:self];
	
    [super dealloc];
}

// the following are delegate things, so you can have some control over JB from client

- (id) delegate
{
    return _delegate;
}

- (void) setDelegate: (id) new_delegate
{
    _delegate = new_delegate;
}

- (void) pauseSong
{
	if ([_delegate respondsToSelector:@selector(pauseSong)])
        [_delegate pauseSong];
    else
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to -pauseSong"];
}

- (void) skipSong
{
	if ([_delegate respondsToSelector:@selector(skipSong)])
        [_delegate skipSong];
    else
        [NSException raise:NSInternalInconsistencyException
					format:@"Delegate doesn't respond to -skipSong"];
}

@end
