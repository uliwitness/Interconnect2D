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
#import "ICGConversation.h"
#import "ICGGameToolTalk.h"


@interface ICGAppDelegate ()

@property (weak) IBOutlet NSWindow          *window;
@property (weak) IBOutlet ICGGameView       *gameView;
@property (copy) NSString                   *filePath;

@end

@implementation ICGAppDelegate

-(BOOL) application:(NSApplication *)sender openFile:(NSString *)filename
{
    BOOL    success = YES;
    if( self.filePath )
    {
        [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"willSave"];
        if( ![self.gameView writeToFile: self.filePath] )
        {
            [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"didFailToSave"];
            NSAlert *   alert = [NSAlert new];
            alert.messageText = @"Failed to save previous document";
            alert.informativeText = [NSString stringWithFormat: @"Couldn't save to %@", self.filePath];
            [alert addButtonWithTitle: @"OK"];
            [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode){}];
            return NO;
        }
        else
        {
            [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"didSave"];
        }
    }
    else
    {
        self.filePath = filename;
        success = [self.gameView readFromFile: self.filePath];
        if( success )
        {
            [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"didLoad"];
            [self.gameView refreshItemDisplay];
        }
    }
    
    return success;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if( !self.filePath )
        self.filePath = @"GameDump.data";
    if( ![self.gameView readFromFile: self.filePath] )
    {
        NSLog(@"Generating sample file.");
        
        ICGActor    *   thePlayer = [ICGActor new];
        thePlayer.name = @"KateHelios";
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
        [thePlayer.tools addObject: tool];
        thePlayer.tool = tool;
        thePlayer.talkTool = [ICGGameToolTalk new];
        thePlayer.talkTool.wielder = thePlayer;
        thePlayer.script = @"function didLoad()\n"
                            "   global.foo = \"Hello, I'm Kate!\\n\"\n"
                            "   io.write( global.foo )\n"
                            "   io.write( \"My name is: \", KateHelios.name, \"\\n\" )\n"
                            "   global.foo = \"This is boring...\\n\"\n"
                            "   io.write( global.foo )\n"
                            "   variables.superiority = \"Complex.\\n\"\n"
                            "   io.write( variables.superiority )\n"
                            "   me.balloonText = \"G'day, mate!\"\n"
                            "   me.setName_(\"Jeff\")\n"
                            "   Jeff.setName_(\"KateHelios\")\n"
                            "end\n";
        self.gameView.player = thePlayer;
        [self.gameView.items addObject: thePlayer];
        
        ICGActor*    obstacle = [ICGActor new];
        obstacle.name = @"ColorPanel";
        obstacle.owningView = self.gameView;
        obstacle.pos = NSMakePoint( 650, 190 );
        obstacle.animation = [ICGAnimation animationNamed: NSImageNameColorPanel];
        imgSize = obstacle.image.size;
        obstacle.defaultTool = self.gameView.player.talkTool;
        obstacle.posOffset = NSMakeSize( truncf(imgSize.width / 2), 0 );
        ICGConversation*        convo = [ICGConversation new];
        id<ICGConversationNode> node = [convo conversationNode: @"hello" message: @"Welcome to the Interconnect!"];
        [node addPlainChoice: @"Thanks!" message: @"Uh... thank you. What is this?"];
        ICGConversationChoice*  cc = [node addPlainChoice: @"Eff You!" message: @"&^%#%@$@!!!!"];
        id<ICGConversationNode> node2 = [convo conversationNode: @"eff you" message: @"Don't you find that a bit rude?"];
        [node2 addPlainChoice: @"You're right." message: @"I'm sorry, you really don't deserve this."];
        cc.nextConversationNode = node2;
        obstacle.playerConversation = convo;
        obstacle.script = @"function didChooseConversationNode(nodeName)\n"
                            "   io.write( \"Chose node: \\\"\", nodeName, \"\\\"\\n\" )\n"
                            "end\n"
                            "\n"
                            "function shouldShowConversationNode(nodeName)\n"
                            "   return nodeName ~= \"Thanks!\"\n"
                            "end\n";
        [self.gameView.items addObject: obstacle];

        obstacle = [ICGActor new];
        obstacle.name = @"Bonjour";
        obstacle.owningView = self.gameView;
        obstacle.pos = NSMakePoint( 550, 150 );
        obstacle.animation = [ICGAnimation animationNamed: NSImageNameBonjour];
        imgSize = obstacle.image.size;
        obstacle.defaultTool = self.gameView.player.tool;
        obstacle.posOffset = NSMakeSize( truncf(imgSize.width / 2), 0 );
        [self.gameView.items addObject: obstacle];
        
        [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"didLoad"];
        
        [self.gameView refreshItemDisplay];
    }
    else
    {
        [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"didLoad"];
        [self.gameView refreshItemDisplay];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"willQuit"];
}


-(void) saveDocument: (id)sender
{
    [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"willSave"];
    if( ![self.gameView writeToFile: self.filePath] )
    {
        [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"didFailToSave"];
        NSAlert *   alert = [NSAlert new];
        alert.messageText = @"Failed to save document";
        alert.informativeText = [NSString stringWithFormat: @"Couldn't save to %@", self.filePath];
        [alert addButtonWithTitle: @"OK"];
        [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode){}];
    }
    else
    {
        [self.gameView.items makeObjectsPerformSelector: @selector(runScript:) withObject: @"didSave"];
    }
}

@end
