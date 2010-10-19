//
//  PhantomSongQueue.m
//  cocoaJukebox
//
//  Created by James Cook on 12/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PhantomSongQueue.h"
#import "DBSong.h"
#import "DBMusicPlayer.h"

#define defaultUrl			[[NSUserDefaults standardUserDefaults] stringForKey:@"kUrlRoot"]
#define stoppedUrl			[NSString stringWithFormat: @"%@/stopped_playing", defaultUrl]
#define nextSongUrl			[NSString stringWithFormat: @"%@/nextsongs.txt", defaultUrl]
#define songUrlEncoding		NSUTF8StringEncoding

#define notificationCenter [NSNotificationCenter defaultCenter]

@implementation PhantomSongQueue

- (id) init {
	self = [super init];
	
	if (self) {
			[notificationCenter addObserver: self selector:@selector(playerDidStop:) 
							   name: kPlayerDidStop object: nil];
	}
	
	return self;
}

- (DBSong *) getNextSong {
	NSLog(@"fetching %@", nextSongUrl);
	
	NSURL *url = [NSURL URLWithString: nextSongUrl];
	NSString *songData = [NSString stringWithContentsOfURL: url encoding: songUrlEncoding error: nil];
	
	NSArray *lines = [songData componentsSeparatedByString: @"\n"];
	
	NSString *key =						[lines objectAtIndex: 0];
	NSString *title =					[lines objectAtIndex: 1];
	NSString *path =					[lines objectAtIndex: 2];
	NSString *artist =					[lines objectAtIndex: 3];
	NSString *album =					[lines objectAtIndex: 4];
//	NSString *genre =					[ lines objectAtIndex: 5];
	BOOL fade =			[(NSString *)	[lines objectAtIndex: 6] isEqualToString: @"true"];
	float ftime =		        [(NSString *)	[lines objectAtIndex: 7] floatValue];
	float vol =			[(NSString *)	[lines objectAtIndex: 8] floatValue];
	
	DBSong *song =		[[DBSong alloc] initWithKey: key
							title:	title
							artist: artist
							album:	album
							path:	path];
	
	[song setSongShouldFadeIn:		fade	];
	[song setSongFadeDuration:		ftime	];
	[song setVolume:				vol		];
	
	NSLog(@"got next song, %@, %d", [song path], [song songShouldFadeIn]);
	return [song autorelease];
}

- (void) playerDidStop: (NSNotification *) aNotification {
	NSURL *url = [NSURL URLWithString: stoppedUrl];
	[NSString stringWithContentsOfURL: url encoding: songUrlEncoding error: nil];
	
}

@end
