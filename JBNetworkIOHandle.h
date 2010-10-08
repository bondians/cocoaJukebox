//
//  JBNetworkIOHandle.h
//  cocoaJukebox
//
//  Created by David Henderson on 10/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSStreamAdditions.h"
#import "DBSong.h"
#import "DBMusicPlayer.h"
#import "SongQueue.h"

typedef struct {
	uint32_t magicNum;
	uint32_t version;
} jookieProtocolHeader;

#define jookieMagic		(('J' << 24) | ('B' << 16) | ('X' << 8) | ('D'))

#define jookieVersion(Maj,Min,Rev)	((uint32_t) (Maj << 24) | ((Min << 16) & 0xFF0000) | (Rev & 0xFFFF))
#define jookieLatestVersion		jookieVersion(0, 1, 0)

typedef struct {
	uint16_t operation;
	uint16_t transaction;
	uint32_t length;
} jookiePacketHeader;

typedef struct {
	jookiePacketHeader header;
	uint8_t *payload;
} jookiePacket;

typedef enum {
	jookieNoop = 0,
	jookieServerReply,
	jookieServerStatus,
	jookieSongRequest,
	jookieQueueSong,
	jookieDequeueSong,
	jookieListQueue,
	jookieListPlayHistory,
	jookieStuffQueue,
	jookieNumOperations,
	jookieGetCurrentSong,
	
	// items >= 0x0100 require objc client implementations
	jookieRequestLocalFile = 260
} jookiePacketOperation;


@interface JBNetworkIOHandle : NSObject {
	id _delegate;
	NSInputStream *inputStream;
	NSOutputStream *outputStream;
	
	DBMusicPlayer *musicPlayer;
}

+ (void) initialize;
+ (unsigned int) connections;

- (id) init;
- (id) initWithInputStream: (NSInputStream*) inStream outputStream: (NSOutputStream *) outStream player: (DBMusicPlayer *)player;

- (void) runServer: (NSObject *) unused;

- (BOOL) sendJookieHandshake;
- (BOOL) validateProtocolHeader;
- (BOOL) handleClient;
- (BOOL) dispatchPacket: (jookiePacket *) packet;

- (int) songRequest: (jookiePacket *) packet;
- (int) dequeueSongForKey: (jookiePacket* ) packet;
- (int) queueSong: (jookiePacket *) packet;
- (int) getCurrentSongKey: (jookiePacket *) packet;
- (int) listQueue: (jookiePacket *) packet;

- (int) requestLocalFile: (jookiePacket *) packet;

- (BOOL) sendJookiePacket: (jookiePacket *) packet;

@end
