//
//  DBSong.h
//  cocoaJukebox
//
//  Created by David Henderson & Mark Schultz on 9/30/05.
//  Copyright 2005 Deep Bondi. All rights reserved.
//
//  Based on previous concepts by 
//  James Cook, Dave and Mark
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

#define kPreLoadTime 2
#define kNoSong -99999

#define DBSongPreloadNotification @"DBSongPreloadNotification"
#define DBSongFadePrepNotification @"DBSongFadePrepNotification"
#define kDBSongDidEndNotification @"DBSongDidEndNotification"

#define IN YES
#define OUT NO

enum DBSongTypes_t {
    DBSongWithPath,
	// Song Should be loaded from it's path key.
    DBSongWithData
	// Song should be loaded from data.
};

@interface DBSong : NSObject
{
	enum DBSongTypes_t DBSongType;
	NSString *key;
	NSString *title;
	NSString *artist;
	NSString *album;
	NSString *path;
	
	NSString *preQueueKey;
	NSString *postQueueKey;
	
	BOOL isPlaying;
	BOOL songShouldFadeIn;
	BOOL cameOverNetwork;
	BOOL isFading;
	double mySongFadeDuration;
	double songFadeInDuration;
	double songFadeOutDuration;
	double fadeEndTime;
	float myVolume;
	NSTimer *fadeOutTimer;
	NSTimer *fadeInTimer;
	//NSTimer *testTimer;
	
	BOOL songIsLoaded;
	QTMovie *myMovie;
	//NSError *myError;
}

- (id) init;
- (id) initWithKey: (NSString *) aKey title: (NSString *) aTitle 
		   artist: (NSString *) anArtist album: (NSString *) anAlbum path: (NSString *) aPath;
- (int) hash;
- (void) dealloc;

- (BOOL) loadSong;
- (BOOL) play;
- (BOOL) startPlaybackWithFade: (double) fadeInTime;
- (void) fadeOutNow: (bool) immediatly length: (double) duration;
- (void) stop;

- (BOOL) isEqual:(id) anObject;

- (QTMovie *) movie;

- (NSString *) key;
- (id) valueForKey: (NSString *) someKey;
- (void) setKey: (NSString *) aKey;

- (NSString *) title;
- (void) setTitle: (NSString *) aTitle;
- (NSString *) artist;
- (void) setArtist: (NSString *) anArtist;
- (NSString *) album;
- (void) setAlbum: (NSString *) anAlbum;

- (NSString *) path;
- (void) setPath: (NSString *) aPath;

- (NSString *) preQueueKey;
- (void) setPreQueueKey: (NSString *) aKey;

- (NSString *) postQueueKey;
- (void) setPostQueueKey: (NSString *) aKey;
//use these for getting and setting movie volumes, not direct movie acess
- (float) volume;
- (void) setVolume: (float) vol;
- (BOOL) isPlaying;
- (BOOL) isFading;
- (void) dumpFadeInTimer;
- (void) dumpFadeOutTimer;
//- (void) prepNext;
//- (void) prepareForPlayback;

- (BOOL) songShouldFadeIn;
- (void) setSongShouldFadeIn: (BOOL) aBool;
- (double) songFadeDuration;
- (void) setSongFadeDuration: (double) duration;

- (double) timeLeft;
- (double) timeToFade;
- (double) halfTimeToFade;

@end
