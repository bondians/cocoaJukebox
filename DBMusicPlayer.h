//
//  DBMusicPlayer.h
//  cocoaJukebox
//
//  Created by David Henderson & Mark Schultz on 10/5/05.
//  Copyright 2005 Deep Bondi. All rights reserved.
//
//  Based on previous concepts by 
//  James Cook, Dave and Mark
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "PhantomSongQueue.h"
#import "DBSong.h"

#define kPlayerDidStart				@"playerDidStart"
#define kPlayerDidStop				@"playerDidStop"
#define kPlayerDidPause				@"playerDidPause"
#define kPlayerDidResumeFromPause	@"playerDidResumeFromPause"
#define kSongDidChange              @"songDidChange"

@interface DBMusicPlayer : NSObject
{
	BOOL serverIsRunning;
	BOOL songIsPaused;
	BOOL songsShouldFade;
	float defaultFadeDuration;
	BOOL respectIndividualFadeDurations;
	BOOL respectIndividualFadeIn;
	BOOL alwaysFadeIn;
	float masterVolume;
	
	PhantomSongQueue *playlist;
	DBSong *currentSong;
	DBSong *nextSong;
	
	NSUserDefaultsController *defaultsController;
	NSUserDefaults *defaults;

	NSTimer *fadeManagerTimer;
	NSTimer *updateVolumeTimer;
	
	int fadeManagerState;
}

+ (id) musicPlayerWithPlayList: (PhantomSongQueue *) aPlayList;
- (void) setPlayList: (PhantomSongQueue *) aPlayList;
- (PhantomSongQueue *) songQueue;
- (void) QTMovieDidEndNotification: (NSNotification *) notification;
- (id) init;
- (id) initWithPlayList: (PhantomSongQueue *) aPlayList;
- (void) fadeManager;
- (void) dumpSong: (DBSong *) song;
- (void) toggleStartStop;
- (void) stopWithAlert: (NSString *) reason;
- (void) skipSong;
- (void) pauseSong;
- (void) setVolume: (float) volume;
- (void) setCurrentTime: (double) someTime;
- (float) getVolume;
- (void) updateVolume;
- (BOOL) serverRunning;
- (NSString *) currentSongKey;
- (DBSong *) currentSong;

- (void) mySetNextSong: (DBSong *) newSong;
- (void) mySetCurrentSong: (DBSong *) newSong;

@end


