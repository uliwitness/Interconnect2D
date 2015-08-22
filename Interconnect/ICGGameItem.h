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

@property (assign,nonatomic) NSPoint                pos;
@property (assign,nonatomic) NSSize                 posOffset;
@property (strong,nonatomic) ICGAnimation*          animation;
@property (strong,nonatomic) ICGGameTool*           tool;
@property (strong,nonatomic) ICGGameTool*           defaultTool;
@property (strong,nonatomic) NSMutableArray*        tools;
@property (strong,nonatomic) ICGGameTool*           talkTool;
@property (strong,nonatomic) NSString*              balloonText;
@property (assign) CGFloat                          stepSize;
@property (strong,nonatomic) NSImage*               image;
@property (assign,nonatomic) BOOL                   isInteractible;
@property (weak,nonatomic) ICGGameView*             owningView;
@property (assign,nonatomic) NSInteger              animationFrameIndex;

-(void)     drawInRect: (NSRect)imgBox;
-(BOOL)     mouseDownAtPoint: (NSPoint)pos;
-(CGFloat)  distanceToItem: (ICGGameItem*)otherItem;
-(BOOL)     interactWithNearbyItems: (NSArray*)nearbyItems tool: (ICGGameTool*)inTool;
-(ICGGameItem*) moveByX: (CGFloat)x y: (CGFloat)y collidingWithItems: (NSArray*)items;

-(void)     advanceAnimation;

@end
