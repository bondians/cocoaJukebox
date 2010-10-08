//
//  ArrayAdditions.m
//  cocoaJukebox
//
//  Created by David Henderson on 9/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ArrayAdditions.h"

@implementation NSMutableArray (ArrayAdditions)

- (id) popObjectAtIndex: (int) index
{
	id object = [[[self objectAtIndex: index] retain] autorelease];
	[self removeObjectAtIndex: index];
	return object;
}

- (id) popLastObject
{
	id object = [[[self lastObject] retain] autorelease];
	[self removeLastObject];
	return object;
}

- (id) popFirstObject
{
	if ([self count] > 0){
		id object = [[[self objectAtIndex: 0] retain] autorelease];
		[self removeObjectAtIndex: 0];
		return object;
	}
	return nil;
}

- (id) objectForKey: (NSString *) key value: (id) value
{
	id thisObject;
	id foundObject = nil;
	NSEnumerator *usersEnumerator = [self objectEnumerator];

	while (thisObject = [usersEnumerator nextObject])
	{
		if ([[thisObject valueForKey: key] isEqual: value]){
			foundObject = thisObject;
			break;
		}
	}
	
	return foundObject;
}

- (BOOL) containsObjectForKey: (NSString *) key value:(id) value
{
	id thisObject;
	NSEnumerator *usersEnumerator = [self objectEnumerator];
	
	while (thisObject = [usersEnumerator nextObject])
	{
		if ([[thisObject valueForKey: key] isEqual: value]) {
			return YES;
		}
	}
	
	return NO;
}

@end
