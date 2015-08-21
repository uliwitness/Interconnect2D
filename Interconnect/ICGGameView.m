//
//  ICGGameView.m
//  Interconnect
//
//  Created by Uli Kusterer on 21/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameView.h"
#import "ICGGameTool.h"
#import "ICGGameItem.h"


// The bigger this number, the more subtle the perspective effect:
#define PERSPECTIVE_SCALE_MULTIPLIER        200

#define STEP_SIZE                           5
#define KEY_REPEAT_THRESHOLD                0.15     // seconds to wait before sending first key repeat.
#define KEY_REPEAT_INTERVAL                 0.05    // Seconds to wait between each key repeat.


@interface ICGGameKeyEvent ()

@property NSTimeInterval    nextTimeToSend;

@end


@implementation ICGGameKeyEvent

-(BOOL) isEqual:(id)object
{
    if( ![object isKindOfClass: [self class]] )
        return NO;
    return( [(ICGGameKeyEvent*)object keyCode] == self.keyCode );
}


-(NSUInteger)    hash
{
    return self.keyCode;
}

@end




@interface ICGGameView ()

@property (retain,nonatomic) NSMutableArray*        pressedKeys;
@property (retain,nonatomic) NSTimer*               keyRepeatTimer;

@end


@implementation ICGGameView

-(id)   initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder: coder];
    if( self )
    {
        self.pressedKeys = [NSMutableArray new];
        self.items = [NSMutableArray new];
        self.player = [ICGGameItem new];
        self.player.pos = NSMakePoint( 200, 200 );
        self.player.image = [NSImage imageNamed: NSImageNameUser];
        NSSize      imgSize = self.player.image.size;
        self.player.posOffset = NSMakeSize( truncf(imgSize.width / 2), 0 );
        ICGGameTool*    tool = [ICGGameTool new];
        tool.wielder = self.player;
        self.player.talkTool = tool;
        [self.items addObject: self.player];
        
        ICGGameItem*    obstacle = [ICGGameItem new];
        obstacle.pos = NSMakePoint( 250, 120 );
        obstacle.image = [NSImage imageNamed: NSImageNameColorPanel];
        imgSize = obstacle.image.size;
        obstacle.posOffset = NSMakeSize( truncf(imgSize.width / 2), 0 );
        [self.items addObject: obstacle];
        
        [self refreshItemDisplay];
        self.keyRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 target: self selector: @selector(checkForKeyRepeats:) userInfo: nil repeats: YES];
        [self.keyRepeatTimer setFireDate: [NSDate distantFuture]];
    }
    
    return self;
}


-(void) doBackwards: (BOOL)backwards forEachGameItem: (BOOL(^)( ICGGameItem* currItem, NSRect box ))handler
{
    id      list = backwards ? self.items.reverseObjectEnumerator : self.items;
    for( ICGGameItem* currItem in list )
    {
        NSRect      imgBox = { currItem.pos, NSZeroSize };
        imgBox.size = currItem.image.size;
        CGFloat     perspectiveScaleFactor = 1 / (imgBox.origin.y / PERSPECTIVE_SCALE_MULTIPLIER);
        
        imgBox.origin.x = ((imgBox.origin.x -(self.bounds.size.width /2)) * perspectiveScaleFactor) +(self.bounds.size.width /2);
        imgBox.origin.y = ((imgBox.origin.y -(self.bounds.size.height /2)) * perspectiveScaleFactor) +(self.bounds.size.height /2);
        
        imgBox.size.width *= perspectiveScaleFactor;
        imgBox.size.height *= perspectiveScaleFactor;

        imgBox.origin.x -= currItem.posOffset.width * perspectiveScaleFactor;
        imgBox.origin.y += currItem.posOffset.height * perspectiveScaleFactor;
        
        if( !handler( currItem, imgBox ) )
            break;
    }
}


- (void)drawRect: (NSRect)dirtyRect
{
    [self doBackwards: YES forEachGameItem:^( ICGGameItem* currItem, NSRect imgBox )
    {
        if( currItem.isInteractible )
        {
            [NSGraphicsContext saveGraphicsState];
            NSShadow*   shadow = [NSShadow new];
            shadow.shadowBlurRadius = 8.0;
            shadow.shadowColor = [NSColor colorWithCalibratedRed: 1.0 green: 0.4 blue: 0.4 alpha: 0.9];
            [shadow set];
        }
        
        [currItem.image drawInRect: imgBox];
        //NSLog(@"%f,%f",imgBox.size.width,imgBox.size.height);

        if( currItem.isInteractible )
        {
            [NSGraphicsContext restoreGraphicsState];
        }
        
        return YES;
    }];
}


-(void) refreshItemDisplay
{
    [self.items sortUsingComparator: ^(id obj1, id obj2)
    {
        CGFloat diff = [obj1 pos].y -[obj2 pos].y;
        if( diff < 0 )
            return NSOrderedAscending;
        else if( diff > 0 )
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    
    NSArray*    nearbyItems = self.nearbyItems;
    for( ICGGameItem* currItem in nearbyItems )
        currItem.isInteractible = NO;
    for( ICGGameTool* currTool in self.player.tools )
    {
        NSArray*    interactibleItems = [currTool filterNearbyItems: nearbyItems];
        for( ICGGameItem* currItem in interactibleItems )
            currItem.isInteractible = YES;
    }
    
    if( self.player.talkTool )
    {
        NSArray*    interactibleItems = [self.player.talkTool filterNearbyItems: nearbyItems];
        for( ICGGameItem* currItem in interactibleItems )
            currItem.isInteractible = YES;
    }
    
    [self setNeedsDisplay: YES];
    
    //NSLog(@"Player coordinate %f,%f image size %f,%f", self.player.pos.x, self.player.pos.y, self.player.image.size.width, self.player.image.size.height);
}


- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint     hitPos = [self convertPoint: theEvent.locationInWindow fromView: nil];
    [self doBackwards: NO forEachGameItem:^( ICGGameItem* currItem, NSRect imgBox )
    {
        if( NSPointInRect( hitPos, imgBox ) )
        {
            NSPoint     convertedHitPos = { (hitPos.x -imgBox.origin.x) / (currItem.image.size.width / imgBox.size.width),
                                            (hitPos.y -imgBox.origin.y) / (currItem.image.size.height / imgBox.size.height)};
            if( [currItem mouseDownAtPoint: convertedHitPos] )  // Was hit! We're done looping!
                return NO;
        }
        
        return YES;
    }];
}


-(BOOL) acceptsFirstResponder
{
    return YES;
}


-(BOOL) becomeFirstResponder
{
    return YES;
}


-(void) handleGameKeyDown: (ICGGameKeyEvent*)keyEvt
{
    //NSLog(@"Key %ld pressed%s.", keyEvt.keyCode, keyEvt.isRepeat?" again":"");
    
    switch( keyEvt.keyCode )
    {
        case ICGGameKeyCode_LeftArrow:
        case ICGGameKeyCode_SecondaryLeftArrow:
            [self moveLeft];
            break;
        case ICGGameKeyCode_RightArrow:
        case ICGGameKeyCode_SecondaryRightArrow:
            [self moveRight];
            break;
        case ICGGameKeyCode_UpArrow:
        case ICGGameKeyCode_SecondaryUpArrow:
            [self moveUp];
            break;
        case ICGGameKeyCode_DownArrow:
        case ICGGameKeyCode_SecondaryDownArrow:
            [self moveDown];
            break;
        
        case ICGGameKeyCode_Interact:
            if( !keyEvt.isRepeat )
                [self interactWithTool: nil];
            break;
        
        case ICGGameKeyCode_SwitchTool:
            if( !keyEvt.isRepeat )
                [self switchTool];
            break;
            
        case ICGGameKeyCode_Talk:
            if( !keyEvt.isRepeat && self.player.talkTool != nil )
                [self interactWithTool: self.player.talkTool];
            break;
        case ICGGameKeyCode_Tool1:
            if( !keyEvt.isRepeat && self.player.tools.count > 0 )
                [self interactWithTool: self.player.tools[0]];
            break;

        case ICGGameKeyCode_Tool2:
            if( !keyEvt.isRepeat && self.player.tools.count > 1 )
                [self interactWithTool: self.player.tools[1]];
            break;

        case ICGGameKeyCode_Tool3:
            if( !keyEvt.isRepeat && self.player.tools.count > 2 )
                [self interactWithTool: self.player.tools[2]];
            break;

        case ICGGameKeyCode_Tool4:
            if( !keyEvt.isRepeat && self.player.tools.count > 3 )
                [self interactWithTool: self.player.tools[3]];
            break;

        case ICGGameKeyCode_Tool5:
            if( !keyEvt.isRepeat && self.player.tools.count > 4 )
                [self interactWithTool: self.player.tools[4]];
            break;

        case ICGGameKeyCode_Tool6:
            if( !keyEvt.isRepeat && self.player.tools.count > 5 )
                [self interactWithTool: self.player.tools[5]];
            break;

        case ICGGameKeyCode_Tool7:
            if( !keyEvt.isRepeat && self.player.tools.count > 6 )
                [self interactWithTool: self.player.tools[6]];
            break;

        case ICGGameKeyCode_Tool8:
            if( !keyEvt.isRepeat && self.player.tools.count > 7 )
                [self interactWithTool: self.player.tools[7]];
            break;

        case ICGGameKeyCode_Tool9:
            if( !keyEvt.isRepeat && self.player.tools.count > 8 )
                [self interactWithTool: self.player.tools[8]];
            break;

        case ICGGameKeyCode_Tool0:
            if( !keyEvt.isRepeat && self.player.tools.count > 9 )
                [self interactWithTool: self.player.tools[9]];
            break;
    }
}


-(void) handleGameKeyUp: (ICGGameKeyEvent*)keyEvt
{
    //NSLog(@"Key %ld released", keyEvt.keyCode);
}


-(void) keyDown:(NSEvent *)theEvent
{
    if( theEvent.isARepeat )
        return;
    
    NSInteger       count = theEvent.charactersIgnoringModifiers.length;
    for( NSInteger x = 0; x < count; x++ )
    {
        unichar             theCharacter = [theEvent.charactersIgnoringModifiers characterAtIndex: x];
        ICGGameKeyEvent*    keyEvent = [ICGGameKeyEvent new];
        keyEvent.keyCode = theCharacter;
        NSTimeInterval      nextFireTime = [NSDate timeIntervalSinceReferenceDate] +KEY_REPEAT_THRESHOLD;
        keyEvent.nextTimeToSend = nextFireTime;
        keyEvent.isRepeat = NO;
        
        if( [self.pressedKeys containsObject: keyEvent] )
            [self.pressedKeys removeObject: keyEvent];
        [self.pressedKeys addObject: keyEvent];
        
        if( self.keyRepeatTimer.fireDate == [NSDate distantFuture]
            || nextFireTime < self.keyRepeatTimer.fireDate.timeIntervalSinceReferenceDate )
        {
            self.keyRepeatTimer.fireDate = [NSDate dateWithTimeIntervalSinceReferenceDate: nextFireTime];
        }
        
        [self handleGameKeyDown: keyEvent];
    }
}


-(void) keyUp:(NSEvent *)theEvent
{
    NSInteger       count = theEvent.charactersIgnoringModifiers.length;
    for( NSInteger x = 0; x < count; x++ )
    {
        unichar theCharacter = [theEvent.charactersIgnoringModifiers characterAtIndex: x];
        for( ICGGameKeyEvent* currEvent in self.pressedKeys )
        {
            if( currEvent.keyCode == theCharacter )
            {
                [self handleGameKeyUp: currEvent];
                [self.pressedKeys removeObject: currEvent];
                break;
            }
        }
    }
}


-(void) checkForKeyRepeats: (NSTimer*)sender
{
    NSTimeInterval  nextFireTime = DBL_MAX;
    NSTimeInterval  currTime = [NSDate timeIntervalSinceReferenceDate];
    for( ICGGameKeyEvent* currEvent in self.pressedKeys )
    {
        if( currTime > currEvent.nextTimeToSend )
        {
            currEvent.nextTimeToSend = currTime +KEY_REPEAT_INTERVAL;
            currEvent.isRepeat = YES;
            [self handleGameKeyDown: currEvent];
            if( currEvent.nextTimeToSend < nextFireTime )
                nextFireTime = currEvent.nextTimeToSend;
        }
        else if( currEvent.nextTimeToSend < nextFireTime )
            nextFireTime = currEvent.nextTimeToSend;
    }
    
    if( nextFireTime == DBL_MAX )
        [sender setFireDate: [NSDate distantFuture]];
    else
        [sender setFireDate: [NSDate dateWithTimeIntervalSinceReferenceDate: nextFireTime]];
}


-(NSMutableArray*)  nearbyItems
{
    NSMutableArray* nearbyItems = [self.items mutableCopy];
    [nearbyItems removeObject: self.player];
    [nearbyItems sortUsingComparator: ^(id obj1, id obj2)
    {
        CGFloat obj1diff = [self.player distanceToItem: obj1];
        CGFloat obj2diff = [self.player distanceToItem: obj2];
        CGFloat diff = obj1diff - obj2diff;
        if( diff < 0 )
            return NSOrderedAscending;
        else if( diff > 0 )
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    return nearbyItems;
}


-(void) interactWithTool: (ICGGameTool*)inTool
{
    [self.player interactWithNearbyItems: self.nearbyItems tool: inTool];
}


-(void) switchTool
{
    NSInteger   idx = [self.player.tools indexOfObject: self.player.tool];
    idx++;
    NSInteger   count = self.player.tools.count;
    if( count < 1 )
        return;
    if( idx >= count )  // Current was last tool?
        idx = 0;    // Wrap around.
    self.player.tool = self.player.tools[idx];
    self.player.tool.wielder = self.player;
    
    NSLog( @"New tool is %@", self.player.tool );
}


-(ICGGameItem*) moveByX: (CGFloat)x y: (CGFloat)y
{
    NSPoint pos = self.player.pos;
    pos.x += x;
    pos.y += y;

    for( ICGGameItem* currItem in self.items )
    {
        if( currItem == self.player )
            continue;
        
        if( pos.y > (currItem.pos.y -ceilf(STEP_SIZE /2))
            && pos.y < (currItem.pos.y +ceilf(STEP_SIZE /2)) )
        {
            if( pos.x >= (currItem.pos.x -currItem.posOffset.width)
                && pos.x <= (currItem.pos.x -currItem.posOffset.width +currItem.image.size.width) )
            {
                return currItem;
            }
        }
    }
    
    self.player.pos = pos;
    [self refreshItemDisplay];
    
    return nil;
}


-(void) moveLeft
{
    [self moveByX: -STEP_SIZE y: 0];
}


-(void) moveRight
{
    [self moveByX: STEP_SIZE y: 0];
}


-(void) moveUp
{
    [self moveByX: 0 y: STEP_SIZE];
}


-(void) moveDown
{
    [self moveByX: 0 y: -STEP_SIZE];
}

@end
