//
//  AppDelegate.m
//  Interconnect
//
//  Created by Uli Kusterer on 16/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGAppDelegate.h"
#import "ICGGameView.h"
#import "ICGGameItem.h"
#import "ICGActor.h"
#import "ICGGameTool.h"
#import "ICGAnimation.h"


@interface ICGAppDelegate ()

@property (weak) IBOutlet NSWindow          *window;
@property (weak) IBOutlet ICGGameView       *gameView;
@property (copy) NSString                   *filePath;

@end

@implementation ICGAppDelegate

-(BOOL) application:(NSApplication *)sender openFile:(NSString *)filename
{
    if( self.filePath && ![self.gameView writeToFile: self.filePath] )
    {
        NSRunAlertPanel( @"Failed to save previous document", @"Couldn't save to %@", @"OK", @"", @"", self.filePath);
        return NO;
    }
    else
    {
        self.filePath = filename;
        return [self.gameView readFromFile: self.filePath];
    }
    
    return YES;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if( !self.filePath )
        self.filePath = @"GameDump.data";
    if( ![self.gameView readFromFile: self.filePath] )
    {
        NSLog(@"Generating sample file.");
        
        ICGActor    *   thePlayer = [ICGActor new];
        thePlayer.owningView = self.gameView;
        thePlayer.pos = NSMakePoint( 600, 200 );
        #if 1
        thePlayer.leftWalkAnimation = [ICGAnimation animationNamed: @"SterntalerWalkAnimation"];
        thePlayer.rightWalkAnimation = [ICGAnimation animationNamed: @"SterntalerWalkAnimationR"];
        thePlayer.animation = thePlayer.leftWalkAnimation;
        #else
        thePlayer.animation = [ICGAnimation animationNamed: NSImageNameUser];
        #endif
        NSSize      imgSize = thePlayer.image.size;
        thePlayer.posOffset = NSMakeSize( truncf(imgSize.width / 2), 0 );
        ICGGameTool*    tool = [ICGGameTool new];
        tool.wielder = thePlayer;
        thePlayer.talkTool = tool;
        self.gameView.player = thePlayer;
        [self.gameView.items addObject: thePlayer];
        
        ICGGameItem*    obstacle = [ICGGameItem new];
        obstacle.owningView = self.gameView;
        obstacle.pos = NSMakePoint( 650, 190 );
        obstacle.animation = [ICGAnimation animationNamed: NSImageNameColorPanel];
        imgSize = obstacle.image.size;
        obstacle.defaultTool = self.gameView.player.talkTool;
        obstacle.posOffset = NSMakeSize( truncf(imgSize.width / 2), 0 );
        [self.gameView.items addObject: obstacle];

        obstacle = [ICGGameItem new];
        obstacle.owningView = self.gameView;
        obstacle.pos = NSMakePoint( 550, 150 );
        obstacle.animation = [ICGAnimation animationNamed: NSImageNameBonjour];
        imgSize = obstacle.image.size;
        obstacle.defaultTool = self.gameView.player.talkTool;
        obstacle.posOffset = NSMakeSize( truncf(imgSize.width / 2), 0 );
        [self.gameView.items addObject: obstacle];
        
        [self.gameView refreshItemDisplay];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}


-(void) saveDocument: (id)sender
{
    if( ![self.gameView writeToFile: self.filePath] )
        NSRunAlertPanel( @"Failed to save", @"Couldn't save to %@", @"OK", @"", @"", self.filePath);
}

@end
