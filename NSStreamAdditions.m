//
//  NSStreamAdditions.m
//
//  Created by John R Chang on Mon Dec 08 2003.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "NSStreamAdditions.h"

#include <netinet/in.h> // struct sockaddr_in
#include <sys/socket.h> // SOCK_STREAM

struct AcceptCallbackInfo {
    id target;
    SEL selector;
    CFRunLoopSourceRef source;
};


@implementation NSStream (JRCAdditions)

static void _SocketAcceptCallBack(CFSocketRef socket, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info);

+ (BOOL) listenOnTCPPort: (unsigned short) port selector: (SEL) didAcceptSelector target: (id) anObject
{
    // Build signature
    struct sockaddr_in sin = { .sin_family = AF_INET, .sin_port = port };   // C99-style designated initializer
    CFDataRef address = CFDataCreateWithBytesNoCopy(NULL, (UInt8 *)&sin, sizeof(struct sockaddr_in), kCFAllocatorNull);
    CFSocketSignature signature = {PF_INET, SOCK_STREAM, IPPROTO_TCP, address};
	
    // Build context
    struct AcceptCallbackInfo * callbackInfo = malloc(sizeof(struct AcceptCallbackInfo));
    callbackInfo->target = anObject;
    callbackInfo->selector = didAcceptSelector;
    callbackInfo->source = NULL;
    CFSocketContext context = { .info = callbackInfo };
	
	// Create a socket
    CFSocketRef socket = CFSocketCreateWithSocketSignature(NULL, &signature, kCFSocketAcceptCallBack, (CFSocketCallBack)&_SocketAcceptCallBack, &context);
	if (socket == NULL)
    {
        free(callbackInfo);
		CFRelease(address);
        return NO;
    }
	
	// Add socket to runloop
    callbackInfo->source = CFSocketCreateRunLoopSource(NULL, socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), callbackInfo->source, kCFRunLoopDefaultMode);
	
    // _SocketAcceptCallBack() must cleanup socket, callbackInfo, and callbackInfo->source.
    
	CFRelease(address);
    return YES;
}

static void _SocketAcceptCallBack(CFSocketRef socket, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    if (info == NULL)
        return; // !!!
	
    struct AcceptCallbackInfo * callbackInfo = (struct AcceptCallbackInfo * )info;
	
    // Create input and output streams
    CFReadStreamRef inputStream;
    CFWriteStreamRef outputStream;
    CFSocketNativeHandle s = *((CFSocketNativeHandle *)data); //CFSocketGetNative(socket);
    CFStreamCreatePairWithSocket(NULL, s, &inputStream, &outputStream);
	
    if (inputStream)
        CFReadStreamSetProperty(inputStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    if (outputStream)
        CFWriteStreamSetProperty(outputStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    // Perform callback
    [callbackInfo->target performSelector:callbackInfo->selector withObject:[(id)inputStream autorelease] withObject:[(id)outputStream autorelease]];
	
	/*
	 // NOTE: Do the following cleanup if you turn off kCFSocketAutomaticallyReenableAcceptCallBack
	 
	 // Invalidate the CFSocket, but keep the native socket open
	 CFOptionFlags flags = CFSocketGetSocketFlags(socket);
	 flags &= ~kCFSocketCloseOnInvalidate;
	 CFSocketSetSocketFlags(socket, flags);
	 CFSocketInvalidate(socket);
	 
	 // Remove CFRunLoopSourceRef
	 CFRunLoopRemoveSource(CFRunLoopGetCurrent(), callbackInfo->source, kCFRunLoopDefaultMode);
	 CFRelease(callbackInfo->source);
	 
	 free(callbackInfo);
	 callbackInfo = NULL;*/
}

@end





