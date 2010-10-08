//
//  JBNetworkIOHandle.m
//  cocoaJukebox
//
//  Created by David Henderson on 10/13/05.
//  Copyright 2005 Deep Bondi. All rights reserved.
//

#import "JBNetworkIOHandle.h"
#import <stdio.h>
#import <errno.h>

static unsigned int connections = 0;
static NSLock *connectionsLock = nil;

@implementation JBNetworkIOHandle

+ (void) initialize
{
	connectionsLock = [[NSLock alloc] init];
}

+ (unsigned int) connections
{
	return connections;
}

- (id) init
{
	if ((self = [super init]) != nil){
		NSLog(@"New Network Handle initting");
		
	}
	return self;
}

- (id) initWithInputStream: (NSInputStream*) inStream outputStream: (NSOutputStream *) outStream player: (DBMusicPlayer *) player
{
	if ((self = [self init]) != nil) {
		inputStream = [inStream retain];
		outputStream = [outStream retain];
		musicPlayer = player;
		
		[inputStream open];
		[outputStream open];
		
		// spin new thread with @selector(runServer:)
		[NSThread detachNewThreadSelector: @selector(runServer:) toTarget: self withObject: nil];
	}
	return self;
}

- (void) dealloc
{
	NSLog (@"handle deallocing%@", [self description]);
	[inputStream close];
    [outputStream close];

	[inputStream release];
    [outputStream release];

	[super dealloc];
}

- (void) runServer: (NSObject *) unused
{
	BOOL alive = YES;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self retain];

	[connectionsLock lock];
	connections ++;
	[connectionsLock unlock];

	// read and write

	alive = [self validateProtocolHeader];
	if (alive) alive = [self sendJookieHandshake];
	while (alive) {
		alive = [self handleClient];
	}
	
	// reads and writes are done, cleanup and destroy

	[connectionsLock lock];
	connections --;
	[connectionsLock unlock];
	[self autorelease];
	[pool release];
}

- (BOOL) validateProtocolHeader
{
	jookieProtocolHeader header;

	if ([inputStream read:(uint8_t *) &header maxLength: sizeof(header)] != sizeof(header)){
		return NO;
	}

	if (ntohl(header.magicNum) != jookieMagic) {
		return NO;
	}

	if (ntohl(header.version) != jookieLatestVersion) {
		return NO;
	}

	return YES;
}

- (BOOL) sendJookieHandshake
{
	jookieProtocolHeader header;
	
    /* create a protocol header */
	header.magicNum = htonl(jookieMagic);
	header.version = htonl(jookieLatestVersion);
	
    /* send out our header */
	if([outputStream write:(uint8_t *) &header maxLength: sizeof(header)] != sizeof(header)) {
		return NO;
	}
	
	return YES;
}

- (BOOL) logPacket: (jookiePacket *) packet
{
    int i;

    NSLog(@"Packet header: operation=%d transaction=%d length=%d",
        packet->header.operation,
        packet->header.transaction,
        packet->header.length);

    if (packet->payload != NULL) {
        NSLog(@"Packet payload:");
        for (i = 0; i < packet->header.length; i += 2)
            NSLog(@"%02X %02X", packet->payload[i], packet->payload[i + 1]);
    }
    else {
        NSLog(@"Packet payload is not allocated.");
    }

    return YES;
}

- (BOOL) handleClient
{
	jookiePacket packet;
    int byteCount;

	byteCount = [inputStream read:(uint8_t *) &(packet.header) maxLength: sizeof(jookiePacketHeader)];
	if (byteCount != sizeof(jookiePacketHeader)) {
		return NO;
	}

    NSLog(@"handleClient: Header -- operation=%d transaction=%d length=%d",
        packet.header.operation, packet.header.transaction, packet.header.length);
	
	packet.header.operation = ntohs(packet.header.operation);
	packet.header.transaction = ntohs(packet.header.transaction);
	packet.header.length = ntohl(packet.header.length);

    NSLog(@"handleClient: Header (postorder) -- operation=%d transaction=%d length=%d",
        packet.header.operation, packet.header.transaction, packet.header.length);

	if (packet.header.length > 0) {
		packet.payload = malloc(packet.header.length);
		if (packet.payload == NULL)
			return NO;
   //     NSLog(@"handleClient: payload malloc() succeeded");

		byteCount = [inputStream read: (uint8_t *) packet.payload maxLength: packet.header.length];
		if (byteCount != packet.header.length) {
			free(packet.payload);
            packet.payload = NULL;
			return NO;
		}
        NSLog(@"handleClient: Payload received, %d bytes", byteCount);
    }

//  return [self logPacket: packet];
	return [self dispatchPacket: &packet];
//  return [self listQueue: packet];
}

- (BOOL) dispatchPacket: (jookiePacket *) packet
{
    jookiePacket statusPacket;
    int status;
    int statusPacketPayload[2];
    BOOL result = YES;

    NSLog(@"dispatchPacket: Header data -- operation=%d transaction=%d length=%d",
        packet->header.operation,
        packet->header.transaction,
        packet->header.length);

// Some commands to add:
// - Set volume (per track, based on index)
// - Set volume (per track, based on dbKey)
// - Set volume (global/default)
// - Set fade parameters, same as for volume
// - Flush entire request queue
// - Flush and auto-reload random queue
// - Delete songs by dbkey (already have command based on index)
// - Pause playback
// - Stop playback/advance to next song
// - Stop playback (require manual restart)
// - Start playback after stop
// - Shut down server

// May want to put in some support for security
// Some commands might require the previous execution of a "authorization"
// command before they are allowed to be used by a given client.
// The 'authorization' command could even make use of *nix user/group
// membership for authentication; *nix supplies std libs to handle searching
// the user database

	switch (packet->header.operation) {
    	case jookieNoop:
            NSLog(@"A");
            status = 0;
            break;

        case jookieServerReply:
            NSLog(@"B");
//          status = [self serverReply];
            break;

        case jookieServerStatus:
            NSLog(@"C");
//          status = [self serverStatus];
            break;

        case jookieSongRequest:
            NSLog(@"D");
            status = [self songRequest: packet];
            break;

        case jookieQueueSong:
            NSLog(@"E");
            status = [self queueSong: packet];
            break;

        case jookieDequeueSong:
            NSLog(@"F");
            status = [self dequeueSongForKey: packet];
            break;

        case jookieListQueue:
            NSLog(@"G");
            status = [self listQueue: packet];
            break;

        case jookieListPlayHistory:
            NSLog(@"H");
//          status = [self listPlayHistory];
            break;

        case jookieStuffQueue:
            NSLog(@"I");
//          status = [self stuffQueue];
            break;
		
		case jookieGetCurrentSong:
			NSLog(@"J");
			status = [self getCurrentSongKey: packet];
			break;
		
		case jookieRequestLocalFile:
			NSLog(@"K");
			status = [self requestLocalFile: packet];
			break;

        default:
            NSLog(@"dispatchPacket: Invalid command/operation: %d",
                packet->header.operation);
            status = EINVAL;        // Invalid argument
            break;
	}

    NSLog(@"dispatchPacket: Command %d returned status %d",
        packet->header.operation, status);

    // Requested command completed
	// Free away the packet
	if (packet->header.operation <= 255) {
		free(packet->payload);
	}
	//free(packet);
    // Follow up with status packet
    
    if (status != 9999) {       // For now, always return status
        statusPacket.header.operation = jookieServerStatus;
        statusPacket.header.transaction = 0;
        statusPacket.header.length = sizeof(statusPacketPayload);
        statusPacket.payload = (uint8_t *) &statusPacketPayload;
        // Refer to libjookie : status.c : jookieReadStatusReply()
        statusPacketPayload[0] = htonl(status ? 1 : 0);    // OK/NOK flag?
        statusPacketPayload[1] = htonl(status);            // errno code (cmd return value)

        result = [self sendJookiePacket: &statusPacket];
    }

	return result;
}

- (int) songRequest: (jookiePacket *) packet
{
	uint32_t songKey;

    void *p = packet->payload;
    uint32_t *n = (uint32_t *) p;
    songKey = ntohl(*n);

    NSLog(@"requestSong header: operation=%d transaction=%d length=%d song=%d",
        packet->header.operation,
        packet->header.transaction,
        packet->header.length,
        songKey);

    NSNumber *theKey = [NSNumber numberWithInt: (int) songKey];
    NSLog (@"requestSong: stringValue of key: %@", [theKey stringValue]);
    [[musicPlayer songQueue] requestSongForKey: [theKey stringValue]];

    return 0;
}

- (int) getCurrentSongKey: (jookiePacket *) packet
{
	jookiePacket returnPacket;
	NSString *key;
	uint32_t returnPayloadLength;
	uint16_t dataLength;
	uint32_t aKey;
	uint16_t i;
	BOOL status;
	
	key = [[[musicPlayer currentSongKey] retain] autorelease];
	
	if (key == nil) {
		return EINVAL;          // playlist ID was (probably) invalid
	}
	
    // Build the return packet payload
	
    dataLength = [key isEqualToString: [NSString string]] ? 0 : 1;
    returnPayloadLength = dataLength * sizeof(int);
	
    if (returnPayloadLength > 0) {
    	returnPacket.payload = (uint8_t *) malloc(returnPayloadLength);
        uint32_t *p = (uint32_t *) returnPacket.payload;
        for (i = 0; i < dataLength; i++) {
            aKey = [key intValue];
            p[i]  = htonl(aKey);
        }
    }
    else
        returnPacket.payload = NULL;
	
    // Build the return packet header
	
	returnPacket.header.operation = 1;
	returnPacket.header.transaction = 0;
	returnPacket.header.length = returnPayloadLength;
	
    // Send response and clean up
	
	status = [self sendJookiePacket: &returnPacket];
	
    if (returnPacket.payload)
        free (returnPacket.payload);
	
    if (status)
        return 0;               // "Everything OK" status code
    else
        return EIO;             // "Error occured" status code
}

- (int) queueSong: (jookiePacket *) packet
{
    BOOL status;
    
    struct {
        uint16_t playlist;
        uint16_t position;
        uint32_t flags;
        uint32_t dbKey;
    } *request = (void *) packet->payload;

    request->playlist = ntohs(request->playlist);
    request->position = ntohs(request->position);
    request->flags = ntohl(request->flags);
    request->dbKey = ntohl(request->dbKey);
    
	NSNumber *theKey = [NSNumber numberWithInt: (int) request->dbKey];

    status = [[musicPlayer songQueue] queueSongForKey: [theKey stringValue]
                                             position: request->position 
                                             inQueue: request->playlist];

    if (status)
        return 0;
    else
        return -1;
}

- (int) dequeueSongForKey: (jookiePacket *) packet
{
    BOOL status;
	struct {
		uint16_t playlist;
		uint16_t pad;
		uint32_t dbKey;
	} *request = (void *) packet->payload;
	
	request->playlist = ntohs(request->playlist);
	request->dbKey = ntohl(request->dbKey);
	
	NSNumber *theKey = [NSNumber numberWithInt: (int) request->dbKey];
	
	status = [[musicPlayer songQueue] dequeueSongForKey: [theKey stringValue] 
	                                          fromQueue: request->playlist ];

    if (status)
        return 0;
    else
        return -1;
}

- (int) listQueue: (jookiePacket *) packet
{
	jookiePacket returnPacket;
	NSArray *keyList;
	uint32_t returnPayloadLength;
	uint16_t dataLength;
	uint32_t aKey;
	uint16_t i;
	BOOL status;

	struct {
		uint16_t playlist;
		uint16_t flags;
		uint16_t position;
		uint16_t maxSongs;
	} *request = (void *) packet->payload;
	
	request->playlist = ntohs(request->playlist);
	request->flags = ntohs(request->flags);
	request->position = ntohs(request->position);
	request->maxSongs = ntohs(request->maxSongs);

    keyList = [[[[musicPlayer songQueue] dbKeysFromQueue: request->playlist] retain] autorelease];

	if (keyList == nil) {
	   return EINVAL;          // playlist ID was (probably) invalid
	}

    // Build the return packet payload

    dataLength = MIN([keyList count], request->maxSongs) - request->position;
    returnPayloadLength = dataLength * sizeof(int);

    if (returnPayloadLength > 0) {
    	returnPacket.payload = (uint8_t *) malloc(returnPayloadLength);
        uint32_t *p = (uint32_t *) returnPacket.payload;
        for (i = 0; i < dataLength; i++) {
            aKey = [[keyList objectAtIndex: (request->position + i)] intValue];
            p[i]  = htonl(aKey);
        }
    }
    else
        returnPacket.payload = NULL;

    // Build the return packet header

	returnPacket.header.operation = 1;
	returnPacket.header.transaction = 0;
	returnPacket.header.length = returnPayloadLength;

    // Send response and clean up

	status = [self sendJookiePacket: &returnPacket];

    // Note to Dave:
    // The creator of dynamically-allocated packet objects has to be
    // responsible for cleaning them up e.g. free()ing them.
    // sendJookiePacket cannot do this, since it can just as easily
    // accept a pointer to a STATIC packet object.
    // I will discuss this with you further when we can chat live.

    if (returnPacket.payload)
        free (returnPacket.payload);

    if (status)
        return 0;               // "Everything OK" status code
    else
        return EIO;             // "Error occured" status code
}


- (int) requestLocalFile: (jookiePacket *) packet
{
	BOOL status = YES;
	NSData *songData;
	
	songData = [NSData dataWithBytesNoCopy: packet->payload length: packet->header.length];
	
	status = [[musicPlayer songQueue] requestSongWithData: songData];
	
	if (status)
        return 0;               // "Everything OK" status code
    else
        return EIO;             // "Error occured" status code
	
}

// Note regarding memory allocation/deallocation schemes:
// Since it is possible to pass a pointer to a STATIC object to
// sendJookiePacket, this routine cannot be responsible for "cleaning up"
// (deallocating) dynamically-allocated packets.  The CALLER must be
// responsible for free()ing any dynamic packet objects it creates.

- (BOOL) sendJookiePacket: (jookiePacket *) packet
{
    uint32_t payloadLength;
    int status;

//  NSLog(@"sendJookiePacket: operation=%d transaction=%d length=%d",
//      packet->header.operation, packet->header.transaction, packet->header.length);

    packet->header.operation = htons(packet->header.operation);
    packet->header.transaction = htons(packet->header.operation);
    payloadLength = packet->header.length;
    packet->header.length = htonl(payloadLength);

	status = [outputStream write: (uint8_t *) &(packet->header) maxLength: sizeof(jookiePacketHeader)];
    if (status != sizeof(jookiePacketHeader))
		return NO;
    else
        NSLog(@"sendJookiePacket: Header sent, %d bytes", status);

    if ((packet->payload != NULL) && (payloadLength > 0)) {
        status = [outputStream write: (uint8_t *) packet->payload maxLength: payloadLength];
        if (status != payloadLength)
            return NO;
        else
            NSLog(@"sendJookiePacket: Payload sent, %d bytes", status);
    }

    return YES;
}


@end
