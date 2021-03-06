//
//  ICGGameItem.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ICGLuaScriptOwningObject.h"


@class ICGGameTool;
@class ICGGameView;
@class ICGAnimation;


@interface ICGGamePathEntry : NSObject

-(CGFloat)  x;
-(CGFloat)  y;

@end


@interface ICGGamePath : NSObject

-(NSUInteger)           count;
-(ICGGamePathEntry*)    objectAtIndexedSubscript: (NSUInteger)idx;

@end


@interface ICGGameItem : ICGLuaScriptOwningObject <NSCoding>

@property (assign,nonatomic) NSPoint                pos;        // Position of this item in the world
@property (assign,nonatomic) NSSize                 posOffset;  // How to align the image over pos.
@property (strong,nonatomic) ICGAnimation*          animation;  // The current series of images.
@property (strong,nonatomic) ICGGameTool*           tool;       // The current tool we'll trigger when asked to interact.
@property (strong,nonatomic) ICGGameTool*           defaultTool;// The tool to use when this object is clicked.
@property (strong,nonatomic) NSMutableArray*        tools;      // All tools we carry, which the user can rotate through with 'Q' and trigger using 'E' (if we're the player).
@property (strong,nonatomic) ICGGameTool*           talkTool;   // The tool to trigger when we're asked to talk to someone (if we're the player, when someone presses 'T'.
@property (strong,nonatomic) NSString*              balloonText;// Text currently displayed over this item in a balloon. Set to NIL for no balloon.
@property (assign) CGFloat                          stepSize;   // How big one step of this character is (in world coordinates, not screen coordinates).
@property (strong,nonatomic) NSImage*               image;              // Private. Current image we're showing.
@property (assign,nonatomic) BOOL                   isInteractible;     // For ICGGameView only. Should we draw highlighted because we're close enough to interact?
@property (assign,nonatomic) NSInteger              animationFrameIndex;// Private. Index of 'image' in 'animation.frames'.

-(BOOL)     mayBePickedUpBy: (ICGGameItem*)actor;

-(void)     drawInRect: (NSRect)imgBox;
-(BOOL)     mouseDownAtPoint: (NSPoint)pos modifiers: (NSEventModifierFlags)mods;
-(CGFloat)  distanceToItem: (ICGGameItem*)otherItem;
-(BOOL)     interactWithNearbyItems: (NSArray*)nearbyItems tool: (ICGGameTool*)inTool;
-(ICGGameItem*) moveByX: (CGFloat)x y: (CGFloat)y collidingWithItems: (NSArray*)items;  // Either moves, or returns which item we'd collide with if we moved.

-(ICGGamePath*) pathFindToItem: (ICGGameItem*)otherItem withObstacles: (NSArray*)items; // Walk towards a target.
-(ICGGamePath*) pathFindAwayFromItem: (ICGGameItem*)otherItem distance: (CGFloat)desiredDistance withObstacles: (NSArray*)items;    // Run away from a threat.

-(void)     advanceAnimation;

@end
