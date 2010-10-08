//
//  ArrayAdditions.h
//  cocoaJukebox
//
//  Created by David Henderson on 9/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSMutableArray (ArrayAdditions)

- (id) popObjectAtIndex: (int) index;
- (id) popLastObject;
- (id) popFirstObject;
- (id) objectForKey: (NSString *) key value: (id) value;
- (BOOL) containsObjectForKey: (NSString *) key value: (id) value;

@end
