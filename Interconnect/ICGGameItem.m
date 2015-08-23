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
#import "ICGAnimation.h"


@interface ICGGamePath ()
{
    ICGGamePathEntry    *   sharedEntry;
    NSMutableData       *   points;
}

-(void) addPoint: (NSPoint)pos;

@end


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
        self.variables = [NSMutableDictionary new];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        self.tools = [aDecoder decodeObjectForKey: @"ICGTools"];
        self.tool = [aDecoder decodeObjectForKey: @"ICGTool"];
        self.defaultTool = [aDecoder decodeObjectForKey: @"ICGDefaultTool"];
        self.talkTool = [aDecoder decodeObjectForKey: @"ICGTalkTool"];
        self.balloonText = [aDecoder decodeObjectForKey: @"ICGBalloonText"];
        self.animation = [aDecoder decodeObjectForKey: @"ICGAnimation"];
        if( self.animation && self.animation.frames.count > 0 )
            self.image = self.animation.frames[0];
        NSSize  po;
        po.width = [aDecoder decodeDoubleForKey: @"ICGPosOffsetWidth"];
        po.height = [aDecoder decodeDoubleForKey: @"ICGPosOffsetHeight"];
        self.posOffset = po;
        self.stepSize = [aDecoder decodeDoubleForKey: @"ICGStepSize"];
        NSPoint     p;
        p.x = [aDecoder decodeDoubleForKey: @"ICGPosX"];
        p.y = [aDecoder decodeDoubleForKey: @"ICGPosY"];
        self.pos = p;
        self.animationFrameIndex = [aDecoder decodeInt64ForKey: @"ICGAnimationFrameIndex"];
        self.variables = [[aDecoder decodeObjectForKey: @"ICGVariables"] mutableCopy];
    }
    
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject: self.tools forKey: @"ICGTools"];
    [aCoder encodeObject: self.tool forKey: @"ICGTool"];
    [aCoder encodeObject: self.defaultTool forKey: @"ICGDefaultTool"];
    [aCoder encodeObject: self.talkTool forKey: @"ICGTalkTool"];
    [aCoder encodeObject: self.balloonText forKey: @"ICGBalloonText"];
    [aCoder encodeObject: self.animation forKey: @"ICGAnimation"];
    [aCoder encodeDouble: self.posOffset.width forKey: @"ICGPosOffsetWidth"];
    [aCoder encodeDouble: self.posOffset.height forKey: @"ICGPosOffsetHeight"];
    [aCoder encodeDouble: self.stepSize forKey: @"ICGStepSize"];
    [aCoder encodeDouble: self.pos.x forKey: @"ICGPosX"];
    [aCoder encodeDouble: self.pos.y forKey: @"ICGPosY"];
    [aCoder encodeInt64: self.animationFrameIndex forKey: @"ICGAnimationFrameIndex"];
    [aCoder encodeObject: self.variables forKey: @"ICGVariables"];
}


-(void) setAnimation:(ICGAnimation *)animation
{
    _animation = animation;
    self.image = animation.frames[0];
    self.animationFrameIndex = 0;
}


-(void) advanceAnimation
{
    NSInteger   numFrames = self.animation.frames.count;
    if( self.animation && numFrames > 0 )
    {
        _animationFrameIndex++;
        if( self.animationFrameIndex >= numFrames )
            self.animationFrameIndex = 0;
        self.image = self.animation.frames[self.animationFrameIndex];
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
        balloonRect.origin.y = NSMaxY(imgBox) + 16;
        
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
    else
    {
        ICGGamePath *   thePath = [self.owningView.player pathFindToItem: self withObstacles: self.owningView.items];
        NSLog( @"thePath = %@", thePath );
    }
    return NO;
}


-(CGFloat)  distanceToItem: (ICGGameItem*)otherItem
{
    CGFloat myLeft = self.pos.x -self.posOffset.width,
            myRight = self.pos.x -self.posOffset.width +self.image.size.width,
            otherLeft = otherItem.pos.x -otherItem.posOffset.width,
            otherRight = otherItem.pos.x -otherItem.posOffset.width +otherItem.image.size.width;
    CGFloat distance = DBL_MAX;
    
    // Our sprite's horizontal line (parallel to the other's!) covers some of the same X area?
    if( (myLeft <= otherRight && myLeft >= otherLeft)
        || (myRight <= otherRight && myRight >= otherLeft)
        || (myLeft <= otherLeft && myRight >= otherRight) )
    {
        // Shortest possible distance between any of the points of two parallel, horizontal lines is Y distance:
        distance = fabs(self.pos.y -otherItem.pos.y);
    }
    else
    {
        // Otherwise we're off to one side, so closest point is either our left or right end to theirs,
        //  so calculate that distance (which may have an odd angle):
        CGFloat xdiff = myLeft -otherRight;
        CGFloat ydiff = self.pos.y -otherItem.pos.y;
        CGFloat leftDistance = sqrt( (xdiff * xdiff) + (ydiff * ydiff) );
        xdiff = myRight -otherLeft;
        CGFloat rightDistance = sqrt( (xdiff * xdiff) + (ydiff * ydiff) );
        
        distance = leftDistance;
        if( distance > rightDistance )
            distance = rightDistance;
    }
    
    return distance;
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


-(void) applyCostToGrid: (NSUInteger*)costGrid withWidth: (NSUInteger)gridWidth height: (NSUInteger)gridHeight atX: (NSUInteger)x y: (NSUInteger)y toItem: (ICGGameItem*)otherItem withObstacles: (NSArray*)items currentCost: (NSUInteger)currCost
{
    NSUInteger  idx = y * gridWidth + x;
    
    if( costGrid[idx] == NSUIntegerMax )    // Obstacle, already detected, nothing to do.
        return;
    
    if( costGrid[idx] < currCost )    // We already set this one? And it's cheaper than ours?
        return; // Nothing to do then.
    
    for( ICGGameItem* currItem in items )
    {
        if( (currItem.pos.x / gridWidth) == x
            && (currItem.pos.y / gridHeight) == y ) // Collision!
        {
            costGrid[idx] = NSUIntegerMax;
            return;
        }
    }
    
    costGrid[idx] = currCost;
    currCost ++;
    if( x > 0 )
    {
        [self applyCostToGrid: costGrid withWidth: gridWidth height: gridHeight atX: x-1 y: y toItem: otherItem withObstacles: items currentCost: currCost];
    }
    if( x < (gridWidth-1) )
    {
        [self applyCostToGrid: costGrid withWidth: gridWidth height: gridHeight atX: x+1 y: y toItem: otherItem withObstacles: items currentCost: currCost];
    }
    if( y > 0 )
    {
        [self applyCostToGrid: costGrid withWidth: gridWidth height: gridHeight atX: x y: y-1 toItem: otherItem withObstacles: items currentCost: currCost];
    }
    if( x < (gridHeight-1) )
    {
        [self applyCostToGrid: costGrid withWidth: gridWidth height: gridHeight atX: x y: y+1 toItem: otherItem withObstacles: items currentCost: currCost];
    }
}


-(void) addPointsForBestPathInCostGrid: (NSUInteger*)costGrid withWidth: (NSUInteger)gridWidth height: (NSUInteger)gridHeight atX: (NSUInteger)x y: (NSUInteger)y toPath: (ICGGamePath*)path
{
    NSUInteger  idx = y * gridWidth + x;
    NSPoint     currPos = NSZeroPoint;
    NSUInteger  minCost = NSUIntegerMax -1;
    
    if( costGrid[idx] == 0 )    // Already there?
        return; // Done.
    if( costGrid[idx] == NSUIntegerMax )    // Hit obstacle (no way to get closer) ?
        return; // Done.
    
    if( x > 0 )
    {
        NSUInteger  idx2 = y * gridWidth + (x -1);
        if( costGrid[idx2] < minCost && costGrid[idx2] < costGrid[idx] )
        {
            minCost = costGrid[idx2];
            currPos = NSMakePoint(-1,0);
        }
    }
    if( x < (gridWidth-1) )
    {
        NSUInteger  idx2 = y * gridWidth + (x +1);
        if( costGrid[idx2] < minCost && costGrid[idx2] < costGrid[idx] )
        {
            minCost = costGrid[idx2];
            currPos = NSMakePoint(1,0);
        }
    }
    if( y > 0 )
    {
        NSUInteger  idx2 = (y -1) * gridWidth + x;
        if( costGrid[idx2] < minCost && costGrid[idx2] < costGrid[idx] )
        {
            minCost = costGrid[idx2];
            currPos = NSMakePoint(0,-1);
        }
    }
    if( x < (gridHeight-1) )
    {
        NSUInteger  idx2 = (y +1) * gridWidth + x;
        if( costGrid[idx2] < minCost && costGrid[idx2] < costGrid[idx] )
        {
            minCost = costGrid[idx2];
            currPos = NSMakePoint(0,1);
        }
    }
    
    if( minCost != NSUIntegerMax )
    {
        [path addPoint: currPos];
        if( minCost != 0 )
        {
            [self addPointsForBestPathInCostGrid: costGrid withWidth: gridWidth height: gridHeight atX: x + currPos.x y: y + currPos.y toPath: path];
        }
    }
}


-(ICGGamePath*) pathFindToItem: (ICGGameItem*)otherItem withObstacles: (NSArray*)items
{
    ICGGamePath     *path = [ICGGamePath new];
    CGFloat         gridSize = self.stepSize;
    NSInteger       gridWidth = self.owningView.bounds.size.width / gridSize;
    NSInteger       gridHeight = self.owningView.bounds.size.height / gridSize;
    NSMutableData*  costGrid = [NSMutableData dataWithLength: gridWidth * gridHeight * sizeof(NSUInteger)];
    NSMutableArray  *obstacles = [items mutableCopy];
    [obstacles removeObject: self];
    [obstacles removeObject: otherItem];
    
    for( NSUInteger n = 0; n < (gridWidth * gridHeight); n++ )
        ((NSUInteger*)costGrid.mutableBytes)[n] = NSUIntegerMax -1; // -1 so we have the highest possible number, as we use NSUIntegerMax to indicate it's an obstacle.
    
    NSUInteger  x = otherItem.pos.x / gridSize,
                y = otherItem.pos.y / gridSize;
    [otherItem applyCostToGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight atX: x y: y toItem: self withObstacles: obstacles currentCost: 0];
    [self addPointsForBestPathInCostGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight atX: self.pos.x / gridSize y: self.pos.y / gridSize toPath: path];
    
    return path;
}

@end


@interface ICGGamePathEntry ()
{
    NSPoint *   pos;
}

@end


@implementation ICGGamePathEntry

-(CGFloat)  x
{
    return pos->x;
}

-(CGFloat)  y
{
    return pos->y;
}


-(void) setPoint: (NSPoint*)newPos
{
    pos = newPos;
}

@end


@implementation ICGGamePath

-(id)   init
{
    self = [super init];
    if( self )
    {
        sharedEntry = [ICGGamePathEntry new];
        points = [NSMutableData new];
    }
    return self;
}

-(NSUInteger)   count
{
    return points.length / sizeof(NSPoint);
}


-(ICGGamePathEntry*)    objectAtIndexedSubscript: (NSUInteger)idx
{
    [sharedEntry setPoint: ((NSPoint*)points.bytes) +idx];
    return sharedEntry;
}


-(void) addPoint: (NSPoint)pos
{
    [points appendBytes: &pos length: sizeof(NSPoint)];
}


-(NSString*)    description
{
    NSMutableString*    desc = [NSMutableString stringWithFormat: @"%@<%p> {", self, self];
    
    NSUInteger  count = self.count;
    for( NSUInteger x = 0 ; x < count; x++ )
    {
        NSPoint*    pos = ((NSPoint*)points.bytes) +x;
        [desc appendFormat: @"%s{ %f, %f }", (x != 0) ? " ," : "", pos->x, pos->y];
    }
    
    [desc appendString: @"}"];
    return desc;
}

@end

