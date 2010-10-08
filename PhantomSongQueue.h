//
//  PhantomSongQueue.h
//  cocoaJukebox
//
//  Created by James Cook on 12/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// read songs from an external command

@class DBSong;

@interface PhantomSongQueue : NSObject {

}

- (DBSong *) getNextSong;

@end
