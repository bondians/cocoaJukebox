/* JukeboxController */

#import <Cocoa/Cocoa.h>
#import <math.h>
#import "PhantomSongQueue.h"
#import "DBSong.h"
#import "DBMusicPlayer.h"
#import "UKPrefsPanel.h"

#define kJookieSkipCurrentSong		@"jookieSkipCurrentSong"
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
}

+ (void) initialize;

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification;
- (IBAction) playerStartStop: (id) sender;
- (IBAction) pause: (id) sender;
- (IBAction) skip: (id) sender;
- (IBAction) showPreferences: (id) sender;

- (void) playerDidPause: (NSNotification *) aNotification;
- (void) playerDidResumeFromPause: (NSNotification *) aNotification;
- (void) playerDidStart: (NSNotification *) aNotification;
- (void) playerDidStop: (NSNotification *) aNotification;
- (void) songDidChange: (NSNotification *) aNotification;

- (void) registerForNotifications;
- (void) updateTimeDisplay;

- (void) skipCurrentSong;

@end
