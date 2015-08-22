//
//  ICGGameItem.m
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameItem.h"
#import "ICGGameTool.h"
#import "ICGGameView.h"


@implementation ICGGameItem

-(id)   init
{
    self = [super init];
    if( self )
    {
        self.tools = [NSMutableArray new];
        self.image = [NSImage imageNamed: NSImageNameApplicationIcon];
        self.posOffset = NSMakeSize( truncf(self.image.size.width /2), 0 );
        self.stepSize = 5;
    }
    
    return self;
}


-(void) setAnimation:(NSArray *)animation
{
    _animation = animation;
    self.image = animation[0];
    self.animationFrameIndex = 0;
}


-(void) advanceAnimation
{
    NSInteger   numFrames = self.animation.count;
    if( self.animation && numFrames > 0 )
    {
        _animationFrameIndex++;
        if( self.animationFrameIndex >= numFrames )
            self.animationFrameIndex = 0;
        self.image = self.animation[self.animationFrameIndex];
    }
}


-(ICGGameItem*) moveByX: (CGFloat)x y: (CGFloat)y collidingWithItems: (NSArray*)items
{    
    NSPoint pos = self.pos;
    pos.x += x;
    pos.y += y;
    
    for( ICGGameItem* currItem in items )
    {
        if( currItem == self )
            continue;
        
        if( pos.y > (currItem.pos.y -ceilf(self.stepSize /2))
            && pos.y < (currItem.pos.y +ceilf(self.stepSize /2)) )
        {
            CGFloat newMinX = (pos.x -self.posOffset.width),
                    newMaxX = (pos.x -self.posOffset.width +self.image.size.width),
                    currItemMinX = (currItem.pos.x -currItem.posOffset.width),
                    currItemMaxX = (currItem.pos.x -currItem.posOffset.width +currItem.image.size.width);
            if( (newMinX <= currItemMaxX && newMaxX >= currItemMinX)
                || (newMaxX >= currItemMinX && newMinX <= currItemMaxX) )
            {
                return currItem;
            }
        }
    }
    
    self.pos = pos;
    [self.owningView refreshItemDisplay];
    
    return nil;
}


-(void) drawInRect: (NSRect)imgBox
{
    if( self.isInteractible )
    {
        [NSGraphicsContext saveGraphicsState];
        NSShadow*   shadow = [NSShadow new];
        shadow.shadowBlurRadius = 8.0;
        shadow.shadowColor = [NSColor colorWithCalibratedRed: 1.0 green: 0.2 blue: 0.0 alpha: 1.0];
        [shadow set];
    }
    
    [self.image drawInRect: imgBox];
    //NSLog(@"%f,%f",imgBox.size.width,imgBox.size.height);

    if( self.isInteractible )
    {
        [NSGraphicsContext restoreGraphicsState];
    }
    
    if( self.balloonText )
    {
        NSDictionary*   balloonAttrs = @{ NSFontAttributeName: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSForegroundColorAttributeName: NSColor.lightGrayColor };
        
        NSRect  balloonRect = { NSZeroPoint, [self.balloonText sizeWithAttributes: balloonAttrs] };
        balloonRect.origin.x = NSMidX(imgBox) -truncf(balloonRect.size.width /2);
        balloonRect.origin.y = NSMaxY(imgBox) + 8;
        
        NSBezierPath*   balloonPath = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect( balloonRect, -8, -8 ) xRadius: 8 yRadius:8];
        [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.6] set];
        [balloonPath fill];
        [self.balloonText drawAtPoint: balloonRect.origin withAttributes: balloonAttrs];
    }
}


-(void) setBalloonText:(NSString *)balloonText
{
    _balloonText = balloonText;
    [self.owningView setNeedsDisplay: YES];
}


-(BOOL) mouseDownAtPoint: (NSPoint)pos
{
    if( self.isInteractible )
    {
        [self.owningView.player interactWithNearbyItems: @[ self ] tool: self.defaultTool ? self.defaultTool : nil];
        return YES;
    }
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
