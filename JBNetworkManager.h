//
//  JBNetworkManager.h
//  cocoaJukebox
//
//  Created by David Henderson on 10/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSStreamAdditions.h"
#import "JBNetworkIOHandle.h"

#define kJookieDefaultPort 1289

@class DBMusicPlayer;

@interface JBNetworkManager : NSObject
{
	NSStream *myStream;
	unsigned int maxConnections;
	DBMusicPlayer *musicPlayer;
}

- (id) init;
- (void) didAcceptConnectionWithInputStream: (NSInputStream *) inputStream
							   outputStream: (NSOutputStream *) outputStream;
- (id) initWithPlayer: (DBMusicPlayer *) player;

@end
