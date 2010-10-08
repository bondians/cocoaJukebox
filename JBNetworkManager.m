//
//  JBNetworkManager.m
//  cocoaJukebox
//
//  Created by David Henderson on 10/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JBNetworkManager.h"
#include <netdb.h>

@implementation JBNetworkManager

- (id) init
{
	self = [super init];
	if (self) {
		struct servent *jookieServEnt;
		int jookiePort;
		
		jookieServEnt = getservbyname("jookie", "tcp");
		if (!jookieServEnt)
			jookiePort = kJookieDefaultPort;
		else
			jookiePort = jookieServEnt->s_port;
		
		maxConnections = 10;
		
		musicPlayer = nil;
		
		[NSStream listenOnTCPPort:jookiePort selector:@selector(didAcceptConnectionWithInputStream:outputStream:) target:self];
	}
	return self;
}

- (id) initWithPlayer: (DBMusicPlayer *) player
{
	self = [self init];
	if (self) {
		musicPlayer = player;	// player guaranteed (per Dave) to outlive this object, so no retain
	}
	return self;
}

- (void) didAcceptConnectionWithInputStream: (NSInputStream *) inputStream outputStream: (NSOutputStream *) outputStream
{
    NSLog (@"Connected!");
	if ([JBNetworkIOHandle connections] >= maxConnections) {
			/* probably should be nice and tell the client they're rejected, but we don't do that right now */
		[inputStream close];
		[outputStream close];
		return;
	}

	JBNetworkIOHandle *newHandle = [[JBNetworkIOHandle alloc] initWithInputStream: inputStream 
																	 outputStream: outputStream 
																		   player: musicPlayer];
	[newHandle release];
}

@end
