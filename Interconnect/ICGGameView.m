//
//  ICGGameView.m
//  Interconnect
//
//  Created by Uli Kusterer on 21/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameView.h"


// The bigger this number, the more subtle the perspective effect:
#define PERSPECTIVE_SCALE_MULTIPLIER        200

#define KEY_REPEAT_THRESHOLD                0.25     // seconds to wait before sending first key repeat.
#define KEY_REPEAT_INTERVAL                 0.15    // Seconds to wait between each key repeat.


typedef NS_ENUM(NSUInteger, ICGGameKeyCode)
{
    ICGGameKeyCode_LeftArrow = NSLeftArrowFunctionKey,
    ICGGameKeyCode_RightArrow = NSRightArrowFunctionKey,
    ICGGameKeyCode_UpArrow = NSUpArrowFunctionKey,
    ICGGameKeyCode_DownArrow = NSDownArrowFunctionKey,
    ICGGameKeyCode_Interact = 'e',
    ICGGameKeyCode_SecondaryLeftArrow = 'a',
    ICGGameKeyCode_SecondaryRightArrow = 'd',
    ICGGameKeyCode_SecondaryUpArrow = 'w',
    ICGGameKeyCode_SecondaryDownArrow = 's',
    ICGGameKeyCode_SwitchItem = 'q',
};


@interface ICGGameKeyEvent : NSObject

@property ICGGameKeyCode    keyCode;
@property NSTimeInterval    nextTimeToSend;
@property BOOL              isRepeat;

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



@interface ICGGameItem : NSObject

@property (assign,nonatomic) NSPoint     pos;
@property (assign,nonatomic) NSSize      posOffset;
@property (strong,nonatomic) NSImage*    image;

-(BOOL) mouseDownAtPoint: (NSPoint)pos;

@end

@implementation ICGGameItem

-(BOOL) mouseDownAtPoint: (NSPoint)pos
{
    return NO;
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
        [self.items addObject: self.player];
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
        [currItem.image drawInRect: imgBox];
        //NSLog(@"%f,%f",imgBox.size.width,imgBox.size.height);
        
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
                [self interact];
            break;
        case ICGGameKeyCode_SwitchItem:
            if( !keyEvt.isRepeat )
                [self switchItem];
            break;
    }
}


-(void) handleGameKeyUp: (ICGGameKeyEvent*)keyEvt
{
    //NSLog(@"Key %ld released", keyEvt.keyCode);
}


-(void) keyDown:(NSEvent *)theEvent
{
    if( theEvent.characters.length < 1 )
        return;
    if( theEvent.isARepeat )
        return;
    
    ICGGameKeyEvent*    keyEvent = [ICGGameKeyEvent new];
    keyEvent.keyCode = [theEvent.characters characterAtIndex: 0];
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


-(void) keyUp:(NSEvent *)theEvent
{
    NSInteger       count = theEvent.characters.length;
    for( NSInteger x = 0; x < count; x++ )
    {
        unichar theCharacter = [theEvent.characters characterAtIndex: x];
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


-(void) interact
{
    NSLog(@"Interact");
}


-(void) switchItem
{
    NSLog(@"Switch Item");
}


-(void) moveLeft
{
    NSPoint pos = self.player.pos;
    pos.x -= 10;
    self.player.pos = pos;
    [self refreshItemDisplay];
}


-(void) moveRight
{
    NSPoint pos = self.player.pos;
    pos.x += 10;
    self.player.pos = pos;
    [self refreshItemDisplay];
}


-(void) moveUp
{
    NSPoint pos = self.player.pos;
    pos.y += 10;
    self.player.pos = pos;
    [self refreshItemDisplay];
}


-(void) moveDown
{
    NSPoint pos = self.player.pos;
    pos.y -= 10;
    self.player.pos = pos;
    [self refreshItemDisplay];
}

@end
