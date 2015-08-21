//
//  ICGGameItem.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ICGGameTool;


@interface ICGGameItem : NSObject

@property (assign,nonatomic) NSPoint            pos;
@property (assign,nonatomic) NSSize             posOffset;
@property (strong,nonatomic) NSImage*           image;
@property (strong,nonatomic) ICGGameTool*       tool;
@property (strong,nonatomic) NSMutableArray*    tools;
@property (strong,nonatomic) ICGGameTool*       talkTool;
@property (assign,nonatomic) BOOL               isInteractible;

-(BOOL)     mouseDownAtPoint: (NSPoint)pos;
-(CGFloat)  distanceToItem: (ICGGameItem*)otherItem;
-(BOOL)     interactWithNearbyItems: (NSArray*)nearbyItems tool: (ICGGameTool*)inTool;

@end
