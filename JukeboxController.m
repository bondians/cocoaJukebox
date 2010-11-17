#import "JukeboxController.h"
#import "PhantomSongQueue.h"

@implementation JukeboxController

+ (void) initialize

{
	NSMutableDictionary *appDefaults;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	appDefaults = [[[NSMutableDictionary alloc] init] autorelease];
	
	// advanced preferences
	
	[appDefaults setValue: @"/"								forKey: @"kPathToArchive"];
	[appDefaults setValue: @"http://127.0.0.1:3000"			forKey: @"kUrlRoot"];
	[appDefaults setValue: [NSNumber numberWithBool:YES]	forKey: @"kFadeIsOn"];
	[appDefaults setValue: @"6.0"							forKey: @"kDefaultFadeDuration"];
	[appDefaults setValue: @"1.0"							forKey: @"kMasterVolume"];
	[appDefaults setValue: @"1.0"							forKey: @"kMaxMasterVolume"];
	[appDefaults setValue: @"0.0"							forKey: @"kMinMasterVolume"];
	[appDefaults setValue: [NSNumber numberWithBool:YES]	forKey: @"kRespectIndividualFadeDurations"];
	[appDefaults setValue: [NSNumber numberWithBool:YES]	forKey: @"kRespectSongHinting"];
	[appDefaults setValue: [NSNumber numberWithBool:YES]	forKey: @"kRespectSongFadeIn"];
	[appDefaults setValue: [NSNumber numberWithBool:NO]		forKey: @"kSongAlwaysFadeIn"];
	[appDefaults setValue: @"/Volumes/MajorTuneage/cocoaJukebox/juksite"
															forKey: @"kPathToWebServer"];
	//[appDefaults setValue: @"deepbondi"				forKey: @"kDefaultPlayList"];
	[appDefaults setValue: [NSNumber numberWithBool:NO]		forKey: @"kStartPlaybackOnLaunch"];
	//[appDefaults setValue: @"/archive/mp3.db"       forKey: @"kPathToDatabase"];

	[defaults registerDefaults: appDefaults];
	[defaults synchronize];
	
}
- (id) init
{
	if ((self = [super init]) != nil) {
		// UserDefaults
		defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		[self bind: @"masterVolume" toObject: defaultsController 
	   withKeyPath: @"values.kMasterVolume" options:nil];
	}
	return self;
}

- ( void ) awakeFromNib
{
/*	This code is left in for reference, however it doesn't work well because the
	server it starts does not properly terminate.
	
	task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath: serverRoot];
    [task setLaunchPath: [NSString stringWithFormat: @"%@/script/server", serverRoot]];
    pipe = [[NSPipe alloc] init];
    [task setStandardOutput: pipe];
    file = [pipe fileHandleForReading];
	[task launch];
*/

	[JukeboxController initialize];
}
-(void)applicationWillTerminate:(NSNotification *)notification {
//	if ( task && [task isRunning])
//		[task interrupt];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
	NSLog (@"App did finish launching");	

	//debug stuff
	//NSZombieEnabled = YES;
	// end debug stuff

	mySongQueue = [[PhantomSongQueue alloc] init];
	myMusicPlayer = [[DBMusicPlayer alloc] initWithPlayList: mySongQueue];
	[self registerForNotifications];

	durationTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.5
	target: self selector: @selector(updateTimeDisplay) userInfo: nil repeats: YES] retain];
}

- (IBAction) playerStartStop: (id) sender
{
	[self playerStartStop];
}

- (void) playerStartStop
{
	[myMusicPlayer toggleStartStop];
}

- (IBAction) skip: (id) sender
{
	[self skipCurrentSong];
}

- (void) skipCurrentSong
{
	[myMusicPlayer skipSong];
}

- (IBAction) pause: (id) sender {
	[self playerPause];
}

- (void) playerPause
{
	[myMusicPlayer pauseSong];
}

- (void) playerDidPause: (NSNotification *) aNotification
{
	[pauseResume setTitle: @"Resume"];
	//[pauseResume highlight: YES];
	
}

- (void) playerDidResumeFromPause: (NSNotification *) aNotification
{
	[pauseResume setTitle: @"Pause"];
	//[pauseResume highlight: NO];
}

- (void) playerDidStart: (NSNotification *) aNotification
{
	[startStop setTitle: @"Stop"];
}

- (void) playerDidStop: (NSNotification *) aNotification
{
	[startStop setTitle: @"Start"];
}

- (void) mySetMasterVolume: (NSNotification *) aNotification
{
	NSDictionary *dict;
	myDefaults = [NSUserDefaults standardUserDefaults];
	dict = [aNotification userInfo];
	float newVol = [[dict valueForKey: @"volume"] floatValue];
	[myDefaults setFloat: newVol forKey: @"kMasterVolume"];
        [myDefaults synchronize];
}

+ (NSString *) doubleToTime: (double) time
{
	int itime;
	int minutes, seconds;

	itime = lrint(time);
	seconds = itime % 60;
	minutes = itime / 60;

	return [NSString stringWithFormat: @"%02d:%02d", minutes, seconds];
}

- (void) songDidChange: (NSNotification *) aNotification
{
	NSTimeInterval playTime;

	NSLog(@"songDidChange: %@", [myMusicPlayer currentSong]);

	if ([myMusicPlayer currentSong] && [myMusicPlayer serverRunning]) {
		QTGetTimeInterval([[[myMusicPlayer currentSong] movie] duration], &playTime);
		[dbKeyDisplay setStringValue: [[myMusicPlayer currentSong] key]];
		[songNameDisplay setStringValue: [[myMusicPlayer currentSong] title]];
		[songArtistDisplay setStringValue: [[myMusicPlayer currentSong] artist]];
		[songTimeDisplay setStringValue: [JukeboxController doubleToTime: playTime]];
	}
	else {
		[dbKeyDisplay setStringValue: @"000000"];
		[songNameDisplay setStringValue: @"-- Stopped --"];
		[songArtistDisplay setStringValue: @"-- Stopped --"];
		[songTimeDisplay setStringValue: @"00:00"];
	}
}

- (IBAction) showPreferences:(id)sender
{
	[[[prefsPanel tabView] window] makeKeyAndOrderFront:sender];
}

- (void) updateTimeDisplay
{
	NSTimeInterval currentTime;
	NSTimeInterval playTime;
		if ([myMusicPlayer currentSong]) {
			QTGetTimeInterval([[[myMusicPlayer currentSong] movie] currentTime], &currentTime);
			QTGetTimeInterval([[[myMusicPlayer currentSong] movie] duration], &playTime);
			[songTimeDisplay setStringValue: [JukeboxController doubleToTime: playTime - currentTime]];
		}
}

- (void) registerForNotifications
{
	//- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(NSString *)notificationName object:(id)anObject
// Local Notifications
	[notificationCenter addObserver: self selector:@selector(playerDidStart:) 
							   name: kPlayerDidStart object: myMusicPlayer];
	[notificationCenter addObserver: self selector:@selector(playerDidStop:) 
							   name: kPlayerDidStop object: myMusicPlayer];
	[notificationCenter addObserver: self selector:@selector(playerDidPause:) 
							   name: kPlayerDidPause object: myMusicPlayer];
	[notificationCenter addObserver: self selector:@selector(playerDidResumeFromPause:) 
							   name: kPlayerDidResumeFromPause object: myMusicPlayer];
	[notificationCenter addObserver: self selector:@selector(songDidChange:) 
							   name: kSongDidChange object: myMusicPlayer];
// Distributed Notifications 
	[distributedNotificationCenter addObserver: self selector:@selector(skipCurrentSong)
										  name: kJookiePlayerSkip object: nil];
	[distributedNotificationCenter addObserver: self selector:@selector(playerStartStop)
										  name: kJookiePlayerStartStop object: nil];
	[distributedNotificationCenter addObserver: self selector:@selector(playerPause)
										  name: kJookiePlayerPause object: nil];
	[distributedNotificationCenter addObserver: self selector:@selector(mySetMasterVolume:)
										  name: kJookiePlayerSetVolume object: nil];

}
/*
#define kPlayerDidStart				@"playerDidStart"
#define kPlayerDidStop				@"playerDidStop"
#define kPlayerDidPause				@"playerDidPause"
#define kPlayerDidResumeFromPause	@"playerDidResumeFromPause"
 */

@end
