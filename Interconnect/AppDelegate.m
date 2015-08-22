//
//  AppDelegate.m
//  Interconnect
//
//  Created by Uli Kusterer on 16/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "AppDelegate.h"
#import "ICGGameView.h"
#import "ICGGameItem.h"
#import "ICGActor.h"
#import "ICGGameTool.h"
#import "ICGAnimation.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow          *window;
@property (weak) IBOutlet ICGGameView       *gameView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if( ![self.gameView readFromFile: @"GameDump.data"] )
    {
        NSLog(@"Generating sample file.");
        
        ICGActor    *   thePlayer = [ICGActor new];
        thePlayer.owningView = self.gameView;
        thePlayer.pos = NSMakePoint( 600, 200 );
        thePlayer.leftWalkAnimation = [ICGAnimation animationNamed: @"SterntalerWalkAnimation"];
        thePlayer.rightWalkAnimation = [ICGAnimation animationNamed: @"SterntalerWalkAnimationR"];
        thePlayer.animation = thePlayer.leftWalkAnimation;
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
        
        [self.gameView refreshItemDisplay];
        
        [self.gameView writeToFile: @"GameDump.data"];
    }

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
