//
//  NSStreamAdditions.h
//
//  Created by John R Chang on Mon Dec 08 2003.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

/*
	Limitations of this sample code
 
	Credit: Mike Ash
 
 The string methods are broken for non-ASCII data they will not work with
 strings that have non-ASCII characters for the following two reasons:
 
 The obvious one is that he uses [string length] as the number of bytes, but it's
 the number of unichars, which is not the same for anything except ASCII data
 
 The subtle one is that individual unichars can get split across multiple bytes,
 and it's possible to receive the first part of a unichar in one packet, and the
 last parts in another packet, or to have the first part lie at the end of your
 buffer, in which case the data read from the stream in -readString won't be
 valid UTF-8 and the NSString initialization will fail
 
 Finally the API also encourages you to think of writing one string, and reading
 one string but in fact it's entirely possible for -readString to return a
 partial string, or to return multiple sent strings concatenated together.
 */


#import <Foundation/Foundation.h>

@interface NSStream (JRCAdditions)

+ (BOOL) listenOnTCPPort: (unsigned short) port
						  selector: (SEL) didAcceptSelector
						  target: (id) anObject;
// didAcceptSelector should take the signature:
//    - (void) didAcceptConnectionWithInputStream: (NSInputStream *) outputStream: (NSOutputStream *) outputStream;

@end



