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
#import "ICGAppDelegate.h"


#define PATHFIND_DBG        0

#if PATHFIND_DBG
#define PATHFIND_DBGLOG(argv...)    NSLog(argv)
#else
#define PATHFIND_DBGLOG(argv...)    do{}while(0)
#endif


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
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
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
    }
    
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder: aCoder];
    
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


-(BOOL) mouseDownAtPoint: (NSPoint)pos modifiers: (NSEventModifierFlags)mods
{
    if( (mods & NSAlternateKeyMask) != 0 )
    {
        ICGGamePath *   thePath = [self.owningView.player pathFindAwayFromItem: self distance: self.owningView.player.stepSize * 10 withObstacles: self.owningView.items];
        PATHFIND_DBGLOG(@"thePath = %@", thePath);
        self.owningView.movePath = thePath;
    }
    else if( self.isInteractible )
    {
        [self.owningView.player interactWithNearbyItems: @[ self ] tool: self.defaultTool ? self.defaultTool : nil];
        return YES;
    }
    else
    {
        ICGGamePath *   thePath = [self.owningView.player pathFindToItem: self withObstacles: self.owningView.items];
        PATHFIND_DBGLOG(@"thePath = %@", thePath);
        self.owningView.movePath = thePath;
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


#if PATHFIND_DBG
-(void) dumpCostGrid: (NSUInteger*)costGrid withWidth: (NSUInteger)gridWidth height: (NSUInteger)gridHeight
{
    NSImage*    newImage = [[NSImage alloc] initWithSize: NSMakeSize(gridWidth, gridHeight)];
    [newImage lockFocus];
    
    [NSColor.whiteColor set];
    [NSBezierPath fillRect: NSMakeRect(0, 0, gridWidth, gridHeight)];
    
    for( NSUInteger y = 0 ; y < gridHeight; y++ )
    {
        for( NSUInteger x = 0 ; x < gridWidth; x++ )
        {
            NSUInteger  currCost = *(costGrid +(y * gridWidth) +x);
            if( currCost == NSUIntegerMax )
            {
                [NSColor.lightGrayColor set];
                [NSBezierPath strokeLineFromPoint: NSMakePoint(x +0.5,y +0.5) toPoint: NSMakePoint(x +1.5,y +0.5)];
            }
            else if( currCost != (NSUIntegerMax -1) )
            {
                [NSColor.redColor set];
                [NSBezierPath strokeLineFromPoint: NSMakePoint(x +0.5,y +0.5) toPoint: NSMakePoint(x +1.5,y +0.5)];
            }
        }
    }
    [newImage unlockFocus];
    
    NSImageView*    div = [(ICGAppDelegate*)[NSApplication sharedApplication].delegate debugImageView];
    div.image = newImage;
    [div.window display];
    if( ![div.window isVisible] )
        [div.window orderFront: nil];
}
#endif


-(void) blockOffSurroundingsOfObstacles: (NSArray*)items inGrid: (NSUInteger*)costGrid withWidth: (NSUInteger)gridWidth height: (NSUInteger)gridHeight
{
    for( ICGGameItem* currItem in items )
    {
        NSUInteger  x = [self xAsInt: currItem.pos.x gridWidth: gridWidth],
                    y = [self yAsInt: currItem.pos.y gridHeight: gridHeight];
        NSUInteger  idx = (y * gridWidth) + x;
        
        costGrid[idx] = NSUIntegerMax;
        CGFloat distanceToPass = ceilf((currItem.image.size.width +self.image.size.width) / 2);  // +++ Properly account for posOffset.
        if( idx >= gridWidth )  // Still a row above ours?
        {
            costGrid[ idx -gridWidth ] = NSUIntegerMax; // Consider field above this one a blocker, too.
        }
        if( (idx +gridWidth) < (gridWidth * gridHeight) )  // Still a row below ours?
        {
            costGrid[ idx +gridWidth ] = NSUIntegerMax; // Consider field below this one a blocker, too.
        }
        if( self.stepSize < distanceToPass )
        {
            CGFloat     distance = distanceToPass;
            NSUInteger  passIdx = idx;
            while( distance > 0 )
            {
                if( (passIdx % gridWidth) == 0 )
                    break;
                passIdx--;
                distance -= self.stepSize;
                costGrid[passIdx] = NSUIntegerMax;  // Consider field left of this one a blocker, too, would be covered by the sprite's image.
                if( passIdx >= gridWidth )  // Still a row above ours?
                {
                    costGrid[ passIdx -gridWidth ] = NSUIntegerMax; // Consider field above this one a blocker, too.
                }
                if( (passIdx +gridWidth) < (gridWidth * gridHeight) )  // Still a row below ours?
                {
                    costGrid[ passIdx +gridWidth ] = NSUIntegerMax; // Consider field below this one a blocker, too.
                }
            }
            distance = distanceToPass;
            passIdx = idx;
            while( distance > 0 )
            {
                if( (passIdx % gridWidth) == (gridWidth -1) )
                    break;
                passIdx++;
                distance -= self.stepSize;
                costGrid[passIdx] = NSUIntegerMax;  // Consider field right of this one a blocker, too, would be covered by the sprite's image.
                if( passIdx >= gridWidth )  // Still a row above ours?
                {
                    costGrid[ passIdx -gridWidth ] = NSUIntegerMax; // Consider field above this one a blocker, too.
                }
                if( (passIdx +gridWidth) < (gridWidth * gridHeight) )  // Still a row below ours?
                {
                    costGrid[ passIdx +gridWidth ] = NSUIntegerMax; // Consider field below this one a blocker, too.
                }
            }
        }
    }
}


-(BOOL) applyCostToGrid: (NSUInteger*)costGrid withWidth: (NSUInteger)gridWidth height: (NSUInteger)gridHeight atX: (NSUInteger)x y: (NSUInteger)y toItem: (ICGGameItem*)otherItem withObstacles: (NSArray*)items currentCost: (NSUInteger)currCost
{
    NSUInteger  idx = y * gridWidth + x;
    
    PATHFIND_DBGLOG( @"Examining %lu,%lu looking for %lu,%lu", x, y, [self xAsInt: otherItem.pos.x gridWidth: gridWidth], [self yAsInt: otherItem.pos.y gridHeight: gridHeight] );
    if( x == [self xAsInt: otherItem.pos.x gridWidth: gridWidth] && y == [self yAsInt: otherItem.pos.y gridHeight: gridHeight] )
    {
        PATHFIND_DBGLOG(@"Found goal!");
        costGrid[idx] = currCost; // Ensure that we set this even if it is considered inside the periphery of another obstacle, which is what's usually the case if we're right in front of or behind or next to an item when we start.
        return YES; // Found destination! Yay!
    }
    
    if( costGrid[idx] == NSUIntegerMax )    // Obstacle, already detected, nothing to do.
    {
        PATHFIND_DBGLOG(@"Collided(1) at %lu,%lu", (long)x, (long)y);
        return NO;
    }

    if( costGrid[idx] < currCost )    // We already set this one? And it's cheaper than ours?
    {
        PATHFIND_DBGLOG(@"Nothing to do at %lu,%lu", (long)x, (long)y);
        return NO; // Nothing to do then.
    }

    PATHFIND_DBGLOG(@"Cost at %lu,%lu changed from %lu to %lu", (long)x, (long)y, costGrid[idx], currCost );
    costGrid[idx] = currCost;
    
    #define NUM_DIRECTIONS      4
    struct ICGWeightedDirection
    {
        NSPoint     pos;
        CGFloat     distance;
    }   directions[NUM_DIRECTIONS] = {0,0};
    NSUInteger  currDirIdx = 0;
    
    if( x > 0 )
    {
        CGFloat xdist = (self.stepSize * (x-1)) -otherItem.pos.x,
                ydist = (self.stepSize * y) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(-1,0);
        currDirIdx++;
    }
    if( x < (gridWidth -1) )
    {
        CGFloat xdist = (self.stepSize * (x+1)) -otherItem.pos.x,
                ydist = (self.stepSize * y) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(1,0);
        currDirIdx++;
    }
    if( y > 0 )
    {
        CGFloat xdist = (self.stepSize * x) -otherItem.pos.x,
                ydist = (self.stepSize * (y-1)) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(0,-1);
        currDirIdx++;
    }
    if( y < (gridHeight -1) )
    {
        CGFloat xdist = (self.stepSize * x) -otherItem.pos.x,
                ydist = (self.stepSize * (y +1)) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(0,1);
        currDirIdx++;
    }
    assert( currDirIdx <= NUM_DIRECTIONS );  // If you trigger this, either arrays aren't packed or you forgot to enlarge the directions array when adding an if above.
    
    struct ICGWeightedDirection *   currDirection = NULL;
    while( true )
    {
        // Find direction entry in direction of target item:
        for( NSUInteger n = 0; n < currDirIdx; n++ )
        {
            if( currDirection == NULL || currDirection->distance > directions[n].distance )
                currDirection = directions +n;
        }
        
        if( currDirection == NULL || currDirection->distance == DBL_MAX )
            break;  // Done, no more direction entries left.
        
        #if PATHFIND_DBG
        [self dumpCostGrid: costGrid withWidth: gridWidth height: gridHeight];
        #endif
        
        if( [self applyCostToGrid: costGrid withWidth: gridWidth height: gridHeight atX: x +currDirection->pos.x y: y+ currDirection->pos.y toItem: otherItem withObstacles: items currentCost: currCost +1] )
            return YES; // Found the destination? Terminate early!
        
        currDirection->distance = DBL_MAX;  // Make sure we don't consider this entry again, we already used it.
    }
    
    return NO;
}


-(BOOL) applyCostAwayToGrid: (NSUInteger*)costGrid withWidth: (NSUInteger)gridWidth height: (NSUInteger)gridHeight atX: (NSUInteger)x y: (NSUInteger)y fromItem: (ICGGameItem*)otherItem distance: (CGFloat)desiredDistance withObstacles: (NSArray*)items currentCost: (NSUInteger)currCost finalPosX: (NSUInteger*)outX y: (NSUInteger*)outY
{
    NSUInteger  idx = y * gridWidth + x;
    
    PATHFIND_DBGLOG( @"Examining %lu,%lu looking for %lu,%lu", x, y, [self xAsInt: otherItem.pos.x gridWidth: gridWidth], [self yAsInt: otherItem.pos.y gridHeight: gridHeight] );
    CGFloat xdist = (self.stepSize * (x-1)) -otherItem.pos.x,
            ydist = (self.stepSize * y) -otherItem.pos.y;
    if( sqrt( (xdist * xdist) + (ydist * ydist) ) >= desiredDistance )
    {
        PATHFIND_DBGLOG(@"Found goal!");
        *outX = x;
        *outY = y;
        costGrid[idx] = currCost; // Ensure that we set this even if it is considered inside the periphery of another obstacle, which is what's usually the case if we're right in front of or behind or next to an item when we start.
        return YES; // Found destination! Yay!
    }
    
    if( costGrid[idx] == NSUIntegerMax )    // Obstacle, already detected, nothing to do.
    {
        PATHFIND_DBGLOG(@"Collided(1) at %lu,%lu", (long)x, (long)y);
        return NO;
    }

    if( costGrid[idx] < currCost )    // We already set this one? And it's cheaper than ours?
    {
        PATHFIND_DBGLOG(@"Nothing to do at %lu,%lu", (long)x, (long)y);
        return NO; // Nothing to do then.
    }

    PATHFIND_DBGLOG(@"Cost at %lu,%lu changed from %lu to %lu", (long)x, (long)y, costGrid[idx], currCost );
    costGrid[idx] = currCost;
    
    #define NUM_DIRECTIONS      4
    struct ICGWeightedDirection
    {
        NSPoint     pos;
        CGFloat     distance;
    }   directions[NUM_DIRECTIONS] = {0,0};
    NSUInteger  currDirIdx = 0;
    
    if( x > 0 )
    {
        CGFloat xdist = (self.stepSize * (x-1)) -otherItem.pos.x,
                ydist = (self.stepSize * y) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(-1,0);
        currDirIdx++;
    }
    if( x < (gridWidth -1) )
    {
        CGFloat xdist = (self.stepSize * (x+1)) -otherItem.pos.x,
                ydist = (self.stepSize * y) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(1,0);
        currDirIdx++;
    }
    if( y > 0 )
    {
        CGFloat xdist = (self.stepSize * x) -otherItem.pos.x,
                ydist = (self.stepSize * (y-1)) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(0,-1);
        currDirIdx++;
    }
    if( y < (gridHeight -1) )
    {
        CGFloat xdist = (self.stepSize * x) -otherItem.pos.x,
                ydist = (self.stepSize * (y +1)) -otherItem.pos.y;
        directions[currDirIdx].distance = sqrt( (xdist * xdist) + (ydist * ydist) );
        directions[currDirIdx].pos = NSMakePoint(0,1);
        currDirIdx++;
    }
    assert( currDirIdx <= NUM_DIRECTIONS );  // If you trigger this, either arrays aren't packed or you forgot to enlarge the directions array when adding an if above.
    
    struct ICGWeightedDirection *   currDirection = NULL;
    while( true )
    {
        // Find direction entry in opposite direction of threatening item:
        for( NSUInteger n = 0; n < currDirIdx; n++ )
        {
            if( currDirection == NULL || currDirection->distance < directions[n].distance )
                currDirection = directions +n;
        }
        
        if( currDirection == NULL || currDirection->distance == -1 )
            break;  // Done, no more direction entries left.
        
        #if PATHFIND_DBG
        [self dumpCostGrid: costGrid withWidth: gridWidth height: gridHeight];
        #endif
        
        if( [self applyCostAwayToGrid: costGrid withWidth: gridWidth height: gridHeight atX: x +currDirection->pos.x y: y+ currDirection->pos.y fromItem: otherItem distance: desiredDistance withObstacles: items currentCost: currCost +1 finalPosX: outX y: outY] )
            return YES; // Found the destination? Terminate early!
        
        currDirection->distance = -1;  // Make sure we don't consider this entry again, we already used it.
    }
    
    return NO;
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
    if( y < (gridHeight-1) )
    {
        NSUInteger  idx2 = (y +1) * gridWidth + x;
        if( costGrid[idx2] < minCost && costGrid[idx2] < costGrid[idx] )
        {
            minCost = costGrid[idx2];
            currPos = NSMakePoint(0,1);
        }
    }
    
    if( minCost < (NSUIntegerMax -1) )
    {
        [path addPoint: currPos];
        if( minCost != 0 )
        {
            [self addPointsForBestPathInCostGrid: costGrid withWidth: gridWidth height: gridHeight atX: x + currPos.x y: y + currPos.y toPath: path];
        }
    }
}


-(NSInteger)    xAsInt: (CGFloat)x gridWidth: (NSUInteger)gridWidth
{
    CGFloat xx = x / self.stepSize;
    if( xx < 0 )
        return 0;
    if( xx >= gridWidth )
        return gridWidth -1;
    return xx;
}


-(NSInteger)    yAsInt: (CGFloat)y gridHeight: (NSUInteger)gridHeight
{
    CGFloat yy = y / self.stepSize;
    if( yy < 0 )
        return 0;
    if( yy >= gridHeight )
        return gridHeight -1;
    return yy;
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
    
    NSUInteger  destX = [self xAsInt: otherItem.pos.x gridWidth: gridWidth],
                destY = [self yAsInt: otherItem.pos.y gridHeight: gridHeight];
    NSUInteger  startX = [self xAsInt: self.pos.x gridWidth: gridWidth],
                startY = [self yAsInt: self.pos.y gridHeight: gridHeight];

    PATHFIND_DBGLOG( @"Determining cost: %lu,%lu / %lu,%lu -> %lu,%lu", gridWidth, gridHeight, startX, startY, destX, destY );
    [self blockOffSurroundingsOfObstacles: obstacles inGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight];
    #if PATHFIND_DBG
    [self dumpCostGrid: (NSUInteger*)costGrid.bytes withWidth: gridWidth height: gridHeight];
    #endif
    
    [otherItem applyCostToGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight atX: destX y: destY toItem: self withObstacles: obstacles currentCost: 0];
    
    #if PATHFIND_DBG
    [self dumpCostGrid: (NSUInteger*)costGrid.bytes withWidth: gridWidth height: gridHeight];
    #endif
    
    PATHFIND_DBGLOG( @"Determining path from cost:" );
    
    [self addPointsForBestPathInCostGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight atX: startX y: startY toPath: path];
    
    return path;
}


-(ICGGamePath*) pathFindAwayFromItem: (ICGGameItem*)otherItem distance: (CGFloat)desiredDistance withObstacles: (NSArray*)items
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
    
    NSUInteger  destX = [self xAsInt: otherItem.pos.x gridWidth: gridWidth],
                destY = [self yAsInt: otherItem.pos.y gridHeight: gridHeight];
    NSUInteger  startX = [self xAsInt: self.pos.x gridWidth: gridWidth],
                startY = [self yAsInt: self.pos.y gridHeight: gridHeight];

    PATHFIND_DBGLOG( @"Determining cost: %lu,%lu / %lu,%lu -> %lu,%lu", gridWidth, gridHeight, startX, startY, destX, destY );
    [self blockOffSurroundingsOfObstacles: obstacles inGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight];
    #if PATHFIND_DBG
    [self dumpCostGrid: (NSUInteger*)costGrid.bytes withWidth: gridWidth height: gridHeight];
    #endif
    
    NSUInteger  outX = startX, outY = startY;
    
    desiredDistance += ceilf((otherItem.image.size.width +self.image.size.width) / 2);  // +++ Properly account for posOffset.
    [self applyCostAwayToGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight atX: destX y: destY fromItem: self distance: desiredDistance withObstacles: obstacles currentCost: 0 finalPosX: &outX y: &outY];
    
    #if PATHFIND_DBG
    [self dumpCostGrid: (NSUInteger*)costGrid.bytes withWidth: gridWidth height: gridHeight];
    #endif
    
    PATHFIND_DBGLOG( @"Determining path from cost:" );
    
    [self addPointsForBestPathInCostGrid: (NSUInteger*)costGrid.mutableBytes withWidth: gridWidth height: gridHeight atX: outX y: outY toPath: path];
    
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
    NSMutableString*    desc = [NSMutableString stringWithFormat: @"%@<%p> {", self.className, self];
    
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

