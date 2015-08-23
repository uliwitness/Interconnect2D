//
//  ICGGameItem.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ICGGameTool;
@class ICGGameView;
@class ICGAnimation;


@interface ICGGameItem : NSObject <NSCoding>

@property (assign,nonatomic) NSPoint                pos;        // Position of this item in the world
@property (assign,nonatomic) NSSize                 posOffset;  // How to align the image over pos.
@property (strong,nonatomic) ICGAnimation*          animation;  // The current series of images.
@property (strong,nonatomic) ICGGameTool*           tool;       // The current tool we'll trigger when asked to interact.
@property (strong,nonatomic) ICGGameTool*           defaultTool;// The tool to use when this object is clicked.
@property (strong,nonatomic) NSMutableArray*        tools;      // All tools we carry, which the user can rotate through with 'Q' and trigger using 'E' (if we're the player).
@property (strong,nonatomic) ICGGameTool*           talkTool;   // The tool to trigger when we're asked to talk to someone (if we're the player, when someone presses 'T'.
@property (strong,nonatomic) NSString*              balloonText;// Text currently displayed over this item in a balloon. Set to NIL for no balloon.
@property (assign) CGFloat                          stepSize;   // How big one step of this character is (in world coordinates, not screen coordinates).
@property (strong,nonatomic) NSMutableDictionary*   variables;  // Variables gae logic can use to remember state of this item.
@property (strong,nonatomic) NSImage*               image;              // Private. Current image we're showing.
@property (assign,nonatomic) BOOL                   isInteractible;     // For ICGGameView only. Should we draw highlighted because we're close enough to interact?
@property (weak,nonatomic) ICGGameView*             owningView;         // Subclassers only. The view in which we're being displayed.
@property (assign,nonatomic) NSInteger              animationFrameIndex;// Private. Index of 'image' in 'animation.frames'.

-(void)     drawInRect: (NSRect)imgBox;
-(BOOL)     mouseDownAtPoint: (NSPoint)pos;
-(CGFloat)  distanceToItem: (ICGGameItem*)otherItem;
-(BOOL)     interactWithNearbyItems: (NSArray*)nearbyItems tool: (ICGGameTool*)inTool;
-(ICGGameItem*) moveByX: (CGFloat)x y: (CGFloat)y collidingWithItems: (NSArray*)items;  // Either moves, or returns which item we'd collide with if we moved.

-(void)     advanceAnimation;

@end
