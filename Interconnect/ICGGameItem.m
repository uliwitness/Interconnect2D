//
//  ICGGameItem.m
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameItem.h"
#import "ICGGameTool.h"


@implementation ICGGameItem

-(id)   init
{
    self = [super init];
    if( self )
    {
        self.tools = [NSMutableArray new];
        self.image = [NSImage imageNamed: NSImageNameApplicationIcon];
        self.posOffset = NSMakeSize( truncf(self.image.size.width /2), 0 );
    }
    
    return self;
}


-(BOOL) mouseDownAtPoint: (NSPoint)pos
{
    return NO;
}


-(CGFloat)  distanceToItem: (ICGGameItem*)otherItem
{
    CGFloat xdiff = self.pos.x -otherItem.pos.x;
    CGFloat ydiff = self.pos.y -otherItem.pos.y;
    return sqrt( (xdiff * xdiff) + (ydiff * ydiff) );
}


-(BOOL)     interactWithNearbyItems: (NSArray*)nearbyItems tool: (ICGGameTool*)inTool
{
    if( nearbyItems.count < 1 || (inTool == nil && self.tool == nil) )
        return NO;
    
    if( !inTool )
        inTool = self.tool;
    
    inTool.wielder = self;
    nearbyItems = [inTool filterNearbyItems: nearbyItems];
    
    BOOL        interacted = NO;
    for( ICGGameItem* currItem in nearbyItems )
    {
        //NSLog( @"%@ interacting with item %@", self.image.name, currItem.image.name );
        interacted |= [inTool interactWithItem: currItem];
    }
    
    if( !interacted )
        ;//NSLog( @"Nothing near enough to %@ to interact with.", self.image.name );
    
    return interacted;
}

@end
