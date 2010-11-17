/* JukeboxController */

#import <Cocoa/Cocoa.h>
#import <math.h>
#import "PhantomSongQueue.h"
#import "DBSong.h"
#import "DBMusicPlayer.h"
#import "UKPrefsPanel.h"

#define kJookiePlayerSkip			@"jookiePlayerSkip"
#define kJookiePlayerStartStop		@"jookiePlayerStartStop"
#define kJookiePlayerPause			@"jookiePlayerPause"
#define kJookiePlayerSetVolume		@"jookiePlayerSetVolume"
#define serverRoot					[[NSUserDefaults standardUserDefaults] stringForKey:@"kPathToWebServer"]

#define notificationCenter [NSNotificationCenter defaultCenter]
#define distributedNotificationCenter [NSDistributedNotificationCenter defaultCenter]

// debug
// #import <Foundation/NSDebug.h>

@interface JukeboxController : NSObject
{
	//debug stuff
	
	//UKPrefsPanel *prefsPanel;
	PhantomSongQueue *mySongQueue;
	DBMusicPlayer *myMusicPlayer;
	IBOutlet NSTextField *requestNumber;
	IBOutlet NSButton *startStop;
	IBOutlet NSButton *pauseResume;
	IBOutlet NSButton *additive;
	IBOutlet NSProgressIndicator *playListLoader;
    IBOutlet NSTextField *songArtistDisplay;
    IBOutlet NSTextField *songNameDisplay;
    IBOutlet NSTextField *songTimeDisplay;
	IBOutlet NSTextField *dbKeyDisplay;
	IBOutlet UKPrefsPanel *prefsPanel;
	NSTimer *durationTimer;
	float masterVolume;
	NSUserDefaultsController *defaultsController;
	NSUserDefaults *myDefaults;
	
	// Rails Stuff
	NSTask *task;
	NSPipe *pipe;
	NSFileHandle *file;
}

+ (void) initialize;

- (id) init;
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification;
-(void)applicationWillTerminate:(NSNotification *)notification;
- (IBAction) playerStartStop: (id) sender;
- (IBAction) pause: (id) sender;
- (IBAction) skip: (id) sender;
- (IBAction) showPreferences: (id) sender;

- (void) playerDidPause: (NSNotification *) aNotification;
- (void) playerDidResumeFromPause: (NSNotification *) aNotification;
- (void) playerDidStart: (NSNotification *) aNotification;
- (void) playerDidStop: (NSNotification *) aNotification;
- (void) songDidChange: (NSNotification *) aNotification;
- (void) mySetMasterVolume: (NSNotification *) aNotification;

- (void) registerForNotifications;
- (void) updateTimeDisplay;

- (void) skipCurrentSong;
- (void) playerStartStop;
- (void) playerPause;

@end
