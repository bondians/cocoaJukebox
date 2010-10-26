//
//  DBMusicPlayer.m
//  cocoaJukebox
//
//  Created by David Henderson & Mark Schultz on 10/5/05.
//  Copyright 2005 Deep Bondi. All rights reserved.
//
//  Based on previous concepts by 
//  James Cook, Dave and Mark
//
#import "DBMusicPlayer.h"

#define NO_FADE_IN_OFFSET_PERCENT 30
#define PRELOAD_FUDGE_FACTOR        6.0

@implementation DBMusicPlayer

+ (id) musicPlayerWithPlayList: (PhantomSongQueue *) aPlayList
{
    return [[[self alloc] initWithPlayList: aPlayList] autorelease];
}

- (id) init
{
    self = [super init];
    if (self) {
        serverIsRunning = NO;
        songIsPaused = NO;
        currentSong  = nil;
        nextSong = nil;
        playlist = nil;

        NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
        
        [self bind: @"songsShouldFade" toObject: defaultsController 
              withKeyPath: @"values.kFadeIsOn" options:nil];
        [self bind: @"defaultFadeDuration" toObject: defaultsController 
              withKeyPath: @"values.kDefaultFadeDuration" options:nil];
        [self bind: @"respectIndividualFadeDurations" toObject: defaultsController
              withKeyPath: @"values.kRespectIndividualFadeDurations" options:nil];
        [self bind: @"respectIndividualFadeIn" toObject: defaultsController
              withKeyPath: @"values.kRespectSongFadeIn" options:nil];
        [self bind: @"alwaysFadeIn" toObject: defaultsController
              withKeyPath: @"values.kSongAlwaysFadeIn" options:nil];
        
        fadeManagerTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.1
                        target: self selector: @selector(fadeManager) userInfo: nil repeats: YES] retain];
        updateVolumeTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.1
            target: self selector: @selector(updateVolume) userInfo: nil repeats: YES] retain];
                        
        fadeManagerState = 0;
    }
    
    return self;
}

- (void) dealloc {
    // this is a stub... realistically it's never needed because [DBMusicPlayer dealloc] means the app is over.
    // but it still really ought to be done right.
    
    [self setPlayList: nil];
    [self setNextSong: nil];

    // other things to release:
    // defaultsController // this is probably safe to release, but not necessary... it's theoretically a global
    // fadeManagerTimer   // what cleanup is required?  just release?  Seems like probably have to deactivate
    
    [super dealloc];
}

- (id) initWithPlayList: (PhantomSongQueue *) aPlayList
{
    self = [self init];
    
    if (self) {
        [self setPlayList: aPlayList];
    }
    
    return self;
}

- (void) fadeManager
{
    if (! serverIsRunning || ! songsShouldFade || ! currentSong || ! [currentSong isPlaying]) return;

    NSTimeInterval currentTime;
    NSTimeInterval duration;
    double fadeDuration;
    double timeRemaining;
    int oldState;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (respectIndividualFadeDurations){
        fadeDuration = [currentSong songFadeDuration];
        if (fadeDuration < 0) fadeDuration = defaultFadeDuration;
    } else {
        fadeDuration = defaultFadeDuration;
    }
    
    QTGetTimeInterval([[currentSong movie] duration], &duration);
    QTGetTimeInterval([[currentSong movie] currentTime], &currentTime);

    timeRemaining = duration - currentTime;

    oldState = fadeManagerState;

    switch (fadeManagerState) {
        case 0 :                    // Wait for T+fadeDuration+2
            if (timeRemaining <= (fadeDuration + PRELOAD_FUDGE_FACTOR))
                fadeManagerState++;
            break;

        case 1 :                    // Preload newSong
            [self setNextSong: [playlist getNextSong]];
            if (!nextSong) break;
            fadeManagerState++;
            break;

        case 2 :                    // Initiaize fade-out if needed
            if ((fadeDuration > -0.15) && (fadeDuration < 0.15)) {
                fadeManagerState = 20;
                break;
            }
            [currentSong fadeOutNow: NO length: fadeDuration];
            fadeManagerState++;
            break;

        case 3 :                    // Determine if fade-in is needed
            NSLog(@"fadeManager: State 3, respect=%d song=%d always=%d", respectIndividualFadeIn, [nextSong songShouldFadeIn], alwaysFadeIn);
            if (respectIndividualFadeIn) {
                if ([nextSong songShouldFadeIn])
                    fadeManagerState++;
                else
                    fadeManagerState = 10;
            }
            else if (alwaysFadeIn)
                fadeManagerState++;
            else
                fadeManagerState = 10;
            break;

        case 4 :                    // Wait for fade-in point
            if (timeRemaining > fadeDuration)
                break;
            fadeManagerState++;

        case 5 :                    // Start fade-in
            [nextSong startPlaybackWithFade: fadeDuration];
            fadeManagerState = 100;
            break;

        case 10 :                    // Wait for no-fade-in song start time
            if (timeRemaining > (fadeDuration * NO_FADE_IN_OFFSET_PERCENT / 100.0))
                break;
            fadeManagerState++;

        case 11 :                    // Start newSong w/o fade
            [nextSong play];
            fadeManagerState = 100;
            break;

        case 20 :                    // Songs run together - wait for song end + 0.2 seconds
            if (timeRemaining > 0.2)
                break;
            [nextSong play];
            fadeManagerState = 100;
            break;

        default :
        case 100 :                    // Idle state, wait for currentSong to end
            break;
    }

    if (oldState != fadeManagerState)
        NSLog(@"fadeManager: Previous state = %d, New state = %d", oldState, fadeManagerState);
    
    [pool release];
    return;
}

- (void) setPlayList: (PhantomSongQueue *) aPlayList
{
    if (playlist != aPlayList) {
        id oldSongQueue = playlist;
        playlist = [aPlayList retain];
        [oldSongQueue release];
    }
}

- (PhantomSongQueue *) songQueue
{
    return playlist;
}

- (BOOL) playNextSong
{
    NSLog (@"DBMusicPlayer: -playNextSong: entered");
    NSLog (@"ShouldFade= %i,DefaultFade= %f, respectIndiv= %i, AlwaysFade= %i ", songsShouldFade, defaultFadeDuration, respectIndividualFadeDurations, respectIndividualFadeIn, alwaysFadeIn);
    fadeManagerState = 0;
    NSLog (@"DBMusicPlayer: -playNextSong: old song dumped");
    if (nextSong){
        NSLog (@"DBMusicPlayer: -playNextSong: there was a nextSong to work with %@", [nextSong key]);
        [self setCurrentSong: nextSong];
        [self setNextSong: nil];
    } else {
        [self setCurrentSong: [playlist getNextSong]];
    }

    if (currentSong) {
        if ([currentSong play]) {
            [[NSNotificationCenter defaultCenter] postNotificationName: kSongDidChange object: self];
            return YES;
        } else {
            return [self playNextSong];
        }
    }
    else {
        [self stopWithAlert: @"All of your play queues are empty"];
        [[NSNotificationCenter defaultCenter] postNotificationName: kSongDidChange object: self];
        return NO;
    }
     
}

- (void) QTMovieDidEndNotification: (NSNotification *) notification
{
    switch (serverIsRunning) {
        case NO:
        //  setSong nil fix
            [self setCurrentSong: nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: kSongDidChange object: self];
            break;

        case YES:
            [self playNextSong];
            break;
    }
}

- (void) toggleStartStop
{
    if (songIsPaused) {
        [self pauseSong];
        return;
    }

    switch (serverIsRunning) {
        case NO:
            serverIsRunning = YES;
            
            if ([self playNextSong]) {
                [[NSNotificationCenter defaultCenter] 
                postNotificationName: kPlayerDidStart object: self];
                NSLog(@"toggleStartStop: Server started");
            }
            else {
                serverIsRunning = NO;
            }
            break;
            
        case YES:
            serverIsRunning = NO;
            [self setCurrentSong: nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: kPlayerDidStop object: self];
            [[NSNotificationCenter defaultCenter] postNotificationName: kSongDidChange object: self];
            NSLog(@"toggleStartStop: Server stopped");
            break;
    }
}

-(NSString *) currentSongKey
{
    if (currentSong) 
        return [currentSong key];
    else
        return @"";
}

- (void) stopWithAlert: (NSString *) reason
{
    NSAlert *myAlert = [[[NSAlert alloc] init] autorelease];
    [myAlert setMessageText: @"The player has been stopped"];
    [myAlert setInformativeText: reason];
    [myAlert runModal];
    if (serverIsRunning)
        [self toggleStartStop];
}

- (void) skipSong
{
    switch (serverIsRunning) {
        case NO:
            break;

        case YES:
            if ([currentSong isPlaying])
                [self playNextSong];
            break;
    }
}

- (void) pauseSong
{
    if (serverIsRunning == NO)
        return;

    if (songIsPaused == NO) {
        if (currentSong)
            [currentSong stop];
        if (nextSong)
            [nextSong stop];
        [[NSNotificationCenter defaultCenter] postNotificationName: kPlayerDidPause object: self];
        songIsPaused = YES;
        NSLog(@"pauseSong: Paused");
    }
    else {
        if (currentSong)
            [currentSong play];
        if (nextSong)
            [nextSong play];
        [[NSNotificationCenter defaultCenter] postNotificationName: kPlayerDidResumeFromPause object: self];
        songIsPaused = NO;
        NSLog(@"pauseSong: Playing");
    }
}

- (void) dumpSong: (DBSong *) song
{
        [song stop];
        [[NSNotificationCenter defaultCenter] removeObserver: self
            name:QTMovieDidEndNotification 
            object:[currentSong movie]];
        [[NSNotificationCenter defaultCenter] removeObserver: self
            name:kDBSongDidEndNotification
            object: currentSong];
        [self setCurrentSong: nil];
        [song autorelease];
}

- (BOOL) serverRunning
{
    return serverIsRunning;
}

- (void) setVolume: (float) volume
{
    [[currentSong movie] setVolume: volume];
}

- (void) updateVolume
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (currentSong)
    {
        [[currentSong retain] autorelease];
        [currentSong updateVolume];
    }
    if (nextSong)
    {
        [[nextSong retain] autorelease];
        [nextSong updateVolume];
    }
    [pool release];
}

- (float) getVolume
{
    return [[currentSong movie] volume];
}

- (DBSong *) currentSong
{
    return currentSong;
}

- (void) setNextSong: (DBSong *)newSong {
    if (nextSong != newSong) {
        id oldSong = nextSong;
        nextSong = [newSong retain];
        if (oldSong) [self dumpSong: oldSong];

        if (nextSong != nil && ![nextSong loadSong]) {
            [self dumpSong: nextSong];
            nextSong = nil;
        }
    }
}

- (void) setCurrentSong: (DBSong *)newSong 
{
    DBSong *prospectiveSong;
    if (currentSong != newSong) 
    {
    NSLog(@"gonna try to set this song %@", [newSong title]);
        id oldSong = currentSong;
        if (oldSong) [self dumpSong: oldSong];
          currentSong = nil;
          prospectiveSong = [newSong retain];
        if ([prospectiveSong loadSong]])
        {
            [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(QTMovieDidEndNotification:) 
                name:QTMovieDidEndNotification object:[prospectiveSong movie]];
            [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(QTMovieDidEndNotification:) 
                name:kDBSongDidEndNotification object: prospectiveSong];
        } else {
            [self dumpSong: prospectiveSong];
            prospectiveSong = nil;
        }
        currentSong = prospectiveSong;
    }
}

@end


