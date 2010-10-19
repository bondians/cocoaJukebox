//
//  DBSong.m
//  cocoaJukebox
//
//  Created by David Henderson & Mark Schultz on 9/30/05.
//  Copyright 2005 Deep Bondi. All rights reserved.
//
//  Based on previous concepts by 
//  James Cook, Dave and Mark
//

#import "DBSong.h"

@interface DBSong (Private)

- (void) dumpFadeInTimer;
- (void) dumpFadeOutTimer;

@end

@implementation DBSong

- (id) init
{
	if ((self = [super init]) != nil) {
		key = nil;
		title = nil;
		artist = nil;
		album = nil;
		path = nil;
		myMovie = nil;
		preQueueKey = nil;
		postQueueKey = nil;
		songShouldFadeIn = YES;
		isPlaying = NO;
		isFading = NO;
		mySongFadeDuration = -1;
		myVolume = 0.7;
		songFadeInDuration = 0.0;
		songFadeOutDuration = 0.0;
		fadeEndTime = 0.0;
		fadeOutTimer = nil;
		fadeInTimer = nil;
	}

	return self;
}


- (id) initWithKey: (NSString *) aKey title: (NSString *) aTitle 
		   artist: (NSString *) anArtist album: (NSString *) anAlbum path: (NSString *) aPath
{
	if (! [self init])
		return nil;

	key =    [aKey retain];
	title =  [aTitle retain];
	artist = [anArtist retain];
	album =  [anAlbum retain];
	path =   [aPath retain];

	return self;
}

- (BOOL) loadSong
{
	myMovie = [[QTMovie alloc] initWithFile: [self path] error: nil];
	
	//[myMovie play];
	//[myMovie stop];
	//NSLog(@"Title: %@\n string duration: %@, string currentTime: %@",[self title], QTStringFromTime([myMovie duration]), QTStringFromTime([myMovie currentTime]));
	
	return (myMovie != nil);
}

- (void) dealloc {
	[self dumpFadeInTimer];
        [self dumpFadeOutTimer];
	[myMovie stop];
	[myMovie release];
//      [myMovie autorelease];
	[key release];
	[title release];
	[artist release];
	[album release];
	[path release];
	[preQueueKey release];
	[postQueueKey release];
	[super dealloc];
}


- (BOOL) startPlaybackWithFade: (double) fadeInTime
{
    songFadeInDuration = fadeInTime;

    if ([self loadSong]) {
        [myMovie setVolume: 0.0];

        fadeInTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.1
            target: self selector: @selector(fadeInControl) 
            userInfo: nil repeats: YES] retain];
        isPlaying = YES;
        [myMovie play];

        return YES;
    }

	return NO;
}

- (void) dumpFadeInTimer
{
	if (fadeInTimer){
		if ([fadeInTimer isValid]) [fadeInTimer invalidate];
		if (fadeInTimer) [fadeInTimer release];
		fadeInTimer = nil;
	}
}

- (void) fadeInControl
{
	NSTimeInterval currentTime;
    float newVolume;

	QTGetTimeInterval([myMovie currentTime], &currentTime);

    if (currentTime <= songFadeInDuration) {
        newVolume = myVolume * currentTime / songFadeInDuration;
        [myMovie setVolume: newVolume];
    }
    else {
        [myMovie setVolume: myVolume];
        [self dumpFadeInTimer];
        NSLog (@"fadeInControl: Fade-in completed.");
    }

    return;
}
- (void) fadeOutNow: (bool) immediatly length: (double) fadeDuration
{
    double songDuration;
    double currentTime;
	isFading = YES;

    if (fadeDuration <= 0.01) {
        [myMovie setVolume: 0.0];
        [[NSNotificationCenter defaultCenter]
            postNotificationName: kDBSongDidEndNotification
            object: self];
            return;
    }

    QTGetTimeInterval([myMovie currentTime], &currentTime);
    QTGetTimeInterval([myMovie duration], &songDuration);

    songFadeOutDuration = fadeDuration;
    if (immediatly) {
        fadeEndTime = currentTime + fadeDuration;
    }
    else {
        fadeEndTime = songDuration;
    }

    if (fadeEndTime > songDuration) {
        fadeEndTime = songDuration;
        songFadeOutDuration = songDuration - currentTime;
    }

    fadeOutTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.1
        target: self selector: @selector(fadeOutControl) 
        userInfo: nil repeats: YES] retain];
}

- (void) dumpFadeOutTimer
{
	if (fadeOutTimer){
		if ([fadeOutTimer isValid]) [fadeOutTimer invalidate];
		if (fadeOutTimer) [fadeOutTimer release];
		fadeOutTimer = nil;
	}
}

- (void) fadeOutControl
{
	NSTimeInterval currentTime;
    float newVolume;

	QTGetTimeInterval([myMovie currentTime], &currentTime);

    newVolume = myVolume * (fadeEndTime - currentTime) / songFadeOutDuration;

//  if (newVolume < 0.0) newVolume = 0.0;
    if (newVolume > myVolume) newVolume = myVolume;

    if (newVolume <= 0.01) {
        [self dumpFadeOutTimer];
        NSLog (@"fadeOutControl: Fade-out completed.");
        newVolume = 0.0;
        [[NSNotificationCenter defaultCenter]
            postNotificationName: kDBSongDidEndNotification
            object: self];
    }
    [myMovie setVolume: newVolume];
}

- (BOOL) play
{
    if (isPlaying) {
        [self dumpFadeInTimer];
        [myMovie setVolume: myVolume];
        return YES;
    }

	
	if ([self loadSong])
	{
		[myMovie setVolume: myVolume];
		[myMovie play];
		isPlaying = YES;
		return YES;
	}

	isPlaying = NO;
	return NO;
}

- (void) stop
{
	[myMovie stop];
	isPlaying = NO;
}

- (QTMovie *) movie
{
	return myMovie;
}

- (NSString *) key
{
	return key;
}

- (void) setKey: (NSString *) aKey
{
	[key release];
	key = aKey;
	[key retain];
}

- (NSString *) title
{
	return title;
}

- (void) setTitle: (NSString *) aTitle
{
	[title release];
	title = aTitle;
	[title retain];
}

- (NSString *) artist
{
	return artist;
}

- (void) setArtist: (NSString *) anArtist
{
	[artist release];
	artist = anArtist;
	[artist retain];
}

- (NSString *) album
{
	return album;
}

- (void) setAlbum: (NSString *) anAlbum
{
	[album release];
	album = anAlbum;
	[album retain];
}

- (NSString *) path
{
	return path;
}

- (void) setPath: (NSString *) aPath
{
	[path release];	
	path = aPath;
	[path retain];
}

- (NSString *) preQueueKey
{
	return preQueueKey;
}
- (void) setPreQueueKey: (NSString *) aKey
{
	[preQueueKey release];
	preQueueKey = aKey;
	[preQueueKey retain];
	
}

- (NSString *) postQueueKey
{
	return postQueueKey;
}
- (void) setPostQueueKey: (NSString *) aKey
{
	[postQueueKey release];
	postQueueKey = aKey;
	[postQueueKey retain];
}

- (float) volume
{
	return myVolume;
}

- (void) setVolume: (float) vol
{
	if (myMovie) [myMovie setVolume: vol];
	myVolume = vol;
}

- (BOOL) songShouldFadeIn
{
	return songShouldFadeIn;
}

- (void) setSongShouldFadeIn: (BOOL) aBool
{
	songShouldFadeIn = aBool;
}

- (void) setSongFadeDuration: (double) duration
{
	mySongFadeDuration = duration;
}

- (double) songFadeDuration
{
	return mySongFadeDuration;
}

- (int) hash
{
	return [[self key] intValue];
}

- (BOOL) isEqual: (id) anObject
{
	BOOL Equal = NO;

	if ([[self key] isEqual: [anObject key]]) Equal = YES;

	return Equal;
}

- (double) timeLeft
{
	if (myMovie) {
		NSTimeInterval currentTime;
		NSTimeInterval duration;

		QTGetTimeInterval([myMovie duration], &duration);
		QTGetTimeInterval([myMovie currentTime], &currentTime);
		return duration-currentTime;
	}

	return kNoSong;
}

- (double) timeToFade
{	
	if (myMovie) {
		NSTimeInterval currentTime;
		NSTimeInterval duration;

		QTGetTimeInterval([myMovie duration], &duration);
		QTGetTimeInterval([myMovie currentTime], &currentTime);
		return duration - currentTime - mySongFadeDuration;
	}

	return kNoSong;
}

- (double) halfTimeToFade
{
	if (myMovie) {
		NSTimeInterval currentTime;
		NSTimeInterval duration;

		QTGetTimeInterval([myMovie duration], &duration);
		QTGetTimeInterval([myMovie currentTime], &currentTime);
		return duration - currentTime - (mySongFadeDuration / 2);
	}

	return kNoSong;
}

-(BOOL) isPlaying
{
	return isPlaying;
}
-(BOOL) isFading
{
	return isFading;
}

//KVC Stuff
- (id) valueForKey: (NSString *) someKey
{
	if ([someKey isEqualToString: @"key"] || [someKey isEqualToString: @"Key"])
		return key;
	return key;
}


@end
