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
#import "ICGActor.h"
#import "ICGConversation.h"


// The bigger this number, the more subtle the perspective effect:
#define PERSPECTIVE_SCALE_MULTIPLIER        700

#define KEY_REPEAT_THRESHOLD                0.15    // seconds to wait before sending first key repeat.
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
{
    NSUInteger  _selectedChoice;
    BOOL        _conversationChosen;
}

@property (retain,nonatomic) NSMutableArray*        pressedKeys;
@property (retain,nonatomic) NSTimer*               keyRepeatTimer;
@property (assign,nonatomic) NSUInteger             moveIndex;
@property (retain,nonatomic) NSTimer*               moveTimer;
@property (retain,nonatomic) NSMutableData*         conversationNodeRectArrayStorage;

@end


@implementation ICGGameView

-(id)   initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder: coder];
    if( self )
    {
        self.pressedKeys = [NSMutableArray new];
        self.items = [NSMutableArray new];
        self.variables = [NSMutableDictionary new];

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
        NSRect      imgBox = { currItem.pos, currItem.image.size };
        
        imgBox = [self screenRectFromWorldRect: imgBox withRectOriginOffset: currItem.posOffset];
        
        if( !handler( currItem, imgBox ) )
            break;
    }
}


-(NSPoint)  screenPointFromWorldPoint:(NSPoint)aPoint
{
    CGFloat     perspectiveScaleFactor = (self.bounds.size.height -aPoint.y) / PERSPECTIVE_SCALE_MULTIPLIER;
    
    aPoint.x = ((aPoint.x -(self.bounds.size.width /2)) * perspectiveScaleFactor) +(self.bounds.size.width /2);
    aPoint.y = ((aPoint.y -(self.bounds.size.height /4)) * perspectiveScaleFactor) +(self.bounds.size.height /4);
    return aPoint;
}


-(NSRect)  screenRectFromWorldRect:(NSRect)aBox withRectOriginOffset: (NSSize)posOffset
{
    CGFloat     perspectiveScaleFactor = (self.bounds.size.height -aBox.origin.y) / PERSPECTIVE_SCALE_MULTIPLIER;
    
    aBox.origin.x = ((aBox.origin.x -(self.bounds.size.width /2)) * perspectiveScaleFactor) +(self.bounds.size.width /2);
    aBox.origin.y = ((aBox.origin.y -(self.bounds.size.height /4)) * perspectiveScaleFactor) +(self.bounds.size.height /4);
    
    aBox.size.width *= perspectiveScaleFactor;
    aBox.size.height *= perspectiveScaleFactor;

    aBox.origin.x -= posOffset.width * perspectiveScaleFactor;
    aBox.origin.y += posOffset.height * perspectiveScaleFactor;
    
    return aBox;
}


- (void)drawRect: (NSRect)dirtyRect
{
    NSPoint         floor[4] = { { 1, 1 }, { 1, 300 }, { 1200, 300 }, { 1200, 1 } };
    
    [[NSColor colorWithCalibratedRed:0.341 green:0.753 blue:0.999 alpha:1.000] set];
    NSRect  skyRect = self.bounds;
    skyRect.origin.y = [self screenPointFromWorldPoint: floor[1]].y;
    skyRect.size.height = self.bounds.size.height - skyRect.origin.y;
    [NSBezierPath fillRect: skyRect];
    
    NSBezierPath*   floorPath = [NSBezierPath bezierPath];
    [floorPath moveToPoint: [self screenPointFromWorldPoint: floor[3]]];
    [floorPath lineToPoint: [self screenPointFromWorldPoint: floor[0]]];
    [floorPath lineToPoint: [self screenPointFromWorldPoint: floor[1]]];
    [floorPath lineToPoint: [self screenPointFromWorldPoint: floor[2]]];
    [floorPath lineToPoint: [self screenPointFromWorldPoint: floor[3]]];
    [[NSColor colorWithCalibratedRed:0.058 green:0.439 blue:0.005 alpha:1.000] set];
    [floorPath fill];
    
    [self doBackwards: YES forEachGameItem:^( ICGGameItem* currItem, NSRect imgBox )
    {
        [currItem drawInRect: imgBox];
        
        return YES;
    }];
    
    if( self.conversationNodeRectArrayStorage )
    {
        id<ICGConversationNode> currNode = self.currentConversationNode;
        NSRect*     conversationNodes = (NSRect*) self.conversationNodeRectArrayStorage.mutableBytes;
        NSUInteger  numNodes = (currNode.choices.count +2);
        NSUInteger  currNodeIdx = 0;
        
        [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.4] set];
        [NSBezierPath fillRect: conversationNodes[currNodeIdx++]];
        
        if( !_conversationChosen )  // We're not switching between convos?
        {
            NSDictionary*   attrs = @{ NSFontAttributeName: [NSFont systemFontOfSize: [NSFont systemFontSize]], NSForegroundColorAttributeName: NSColor.whiteColor };
            NSDictionary*   selAttrs = @{ NSFontAttributeName: [NSFont systemFontOfSize: [NSFont systemFontSize]], NSForegroundColorAttributeName: NSColor.selectedTextColor, NSBackgroundColorAttributeName: NSColor.selectedTextBackgroundColor };
            
            [currNode.nodeMessage drawInRect: conversationNodes[currNodeIdx++] withAttributes: attrs];
            
            for( ; currNodeIdx < numNodes; currNodeIdx++ )
            {
                BOOL    isSelected = (currNodeIdx-2) == _selectedChoice;
                if( isSelected )
                {
                    [NSColor.selectedTextBackgroundColor set];
                    [[NSBezierPath bezierPathWithRoundedRect: NSInsetRect(conversationNodes[currNodeIdx],-4,-4) xRadius: 4 yRadius: 4] fill];
                }
                NSString    *   str = [self.currentConversationNode.choices[currNodeIdx-2] choiceName];
                str = [NSString stringWithFormat: @"• %@",str];
                [str drawInRect: conversationNodes[currNodeIdx] withAttributes: (isSelected ? selAttrs : attrs)];
            }
        }
    }
}


-(void) layoutConversationNodeUI
{
    id<ICGConversationNode> currNode = self.currentConversationNode;
    if( currNode == nil )
    {
        self.conversationNodeRectArrayStorage = nil;
    }
    else
    {
        self.conversationNodeRectArrayStorage = [[NSMutableData alloc] initWithLength: sizeof(NSRect) * (currNode.choices.count +2)];
        NSRect*     conversationNodes = (NSRect*) self.conversationNodeRectArrayStorage.mutableBytes;
        
        NSDictionary*   attrs = @{ NSFontAttributeName: [NSFont systemFontOfSize: [NSFont systemFontSize]], NSForegroundColorAttributeName: NSColor.whiteColor };
        NSSize                  measureSize = NSInsetRect(self.bounds,8,8).size;
        CGFloat                 messageHeight = [currNode.nodeMessage boundingRectWithSize: measureSize options: 0 attributes: attrs].size.height;
        CGFloat                 totalHeight = messageHeight;
        NSUInteger              currIdx = 0;
        
        for( ICGConversationChoice* currChoice in currNode.choices )
        {
            totalHeight += [currChoice.choiceName boundingRectWithSize: self.bounds.size options: 0 attributes: attrs].size.height + 8;
        }
        
        NSRect      msgBox = NSInsetRect(self.bounds,8,8);
        msgBox.size.height = totalHeight;
        conversationNodes[currIdx++] = NSInsetRect(msgBox,-8,-8);
        
        msgBox.origin.y = NSMaxY(msgBox) -messageHeight;
        msgBox.size.height = messageHeight;
        conversationNodes[currIdx++] = msgBox;
        
        for( ICGConversationChoice* currChoice in currNode.choices )
        {
            NSString    *   str = [NSString stringWithFormat: @"• %@", currChoice.choiceName];
            CGFloat         currHeight = [str boundingRectWithSize: self.bounds.size options: 0 attributes: attrs].size.height;
            msgBox.origin.y -= currHeight +8;
            msgBox.size.height = currHeight;
            conversationNodes[currIdx++] = msgBox;
        }
    }
}


-(void) setCurrentConversation:(ICGConversation *)currentConversation
{
    _currentConversation = currentConversation;
    [self setCurrentConversationNode: currentConversation.firstNode];
}


-(void) setCurrentConversationNode:(id<ICGConversationNode>)currentConversationNode
{
    _conversationChosen = NO;
    _currentConversationNode = currentConversationNode;
    _selectedChoice = NSUIntegerMax; // Nothing selected.
    [self layoutConversationNodeUI];
    [self setNeedsDisplay: YES];
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
    if( self.currentConversationNode == nil )
    {
        [self doBackwards: NO forEachGameItem:^( ICGGameItem* currItem, NSRect imgBox )
        {
            if( NSPointInRect( hitPos, imgBox ) )
            {
                NSPoint     convertedHitPos = { (hitPos.x -imgBox.origin.x) / (currItem.image.size.width / imgBox.size.width),
                                                (hitPos.y -imgBox.origin.y) / (currItem.image.size.height / imgBox.size.height)};
                if( [currItem mouseDownAtPoint: convertedHitPos modifiers: theEvent.modifierFlags] )  // Was hit! We're done looping!
                    return NO;
            }
            
            return YES;
        }];
    }
    else if( self.conversationNodeRectArrayStorage )
    {
        id<ICGConversationNode> currNode = self.currentConversationNode;
        NSRect*     conversationNodes = (NSRect*) self.conversationNodeRectArrayStorage.mutableBytes;
        NSUInteger  numNodes = (currNode.choices.count +2);
        NSUInteger  currNodeIdx = 2;
        
        for( ; currNodeIdx < numNodes; currNodeIdx++ )
        {
            NSRect      trackingRect = NSInsetRect(conversationNodes[currNodeIdx],-4,-4);
            if( NSPointInRect(hitPos, trackingRect) )
            {
                _selectedChoice = currNodeIdx -2;
                [self setNeedsDisplay: YES];
                [self display];
                
                BOOL        keepTracking = YES;
                while( keepTracking )
                {
                    @autoreleasepool
                    {
                        NSEvent*    currEvent = [[NSApplication sharedApplication] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSRightMouseUpMask | NSOtherMouseUpMask untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
                        if( currEvent )
                        {
                            switch( currEvent.type )
                            {
                              case NSLeftMouseUp:
                              case NSRightMouseUp:
                              case NSOtherMouseUp:
                                keepTracking = NO;
                                break;

                              default:
                              {
                                hitPos = [self convertPoint: currEvent.locationInWindow fromView: nil];
                                if( _selectedChoice != (currNodeIdx -2) && NSPointInRect(hitPos, trackingRect) )
                                {
                                    _selectedChoice = currNodeIdx -2;
                                    [self setNeedsDisplay: YES];
                                }
                                else if( _selectedChoice != NSUIntegerMax && !NSPointInRect(hitPos, trackingRect) )
                                {
                                    _selectedChoice = NSUIntegerMax;
                                    [self setNeedsDisplay: YES];
                                }
                                break;
                              }
                            }
                        }
                    }
                }
                
                if( _selectedChoice != NSUIntegerMax )
                {
                    [self triggerConversationChoice: currNode.choices[_selectedChoice] ];
                }
                break;
            }
        }
    }
}


-(void) triggerConversationChoice: (ICGConversationChoice*)currChoice
{
    self.player.balloonText = currChoice.choiceMessage;
    _conversationChosen = YES;
    [self setNeedsDisplay: YES];
    [self performSelector: @selector(goNextFromConversationChoice:) withObject: currChoice afterDelay: 2.0];
}


-(void) goNextFromConversationChoice: (ICGConversationChoice*)currChoice
{
    self.player.balloonText = nil;
    id<ICGConversationNode> nextNode = [currChoice nextConversationNode];
    [self setCurrentConversationNode: nextNode];
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
    
    if( self.currentConversationNode == nil )
    {
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
                
            case ICGGameKeyCode_SecondaryInteract:
            case ICGGameKeyCode_TertiaryInteract:
                if( !keyEvt.isRepeat )
                    NSBeep();   // Never support these, so users can't accidentally end a conversation that pops up while they are playing.
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
    else
    {
        switch( keyEvt.keyCode )
        {
            case ICGGameKeyCode_UpArrow:
            case ICGGameKeyCode_SecondaryUpArrow:
                if( !keyEvt.isRepeat )
                {
                    _selectedChoice--;
                    id<ICGConversationNode> currNode = self.currentConversationNode;
                    if( _selectedChoice > currNode.choices.count )
                    {
                        _selectedChoice = NSUIntegerMax;    // Make sure pressing "down" immediately shows selection again and user doesn't have to press 3 times to get it back after 3 ups.
                    }
                    
                    [self setNeedsDisplay: YES];
                }
                break;
            case ICGGameKeyCode_DownArrow:
            case ICGGameKeyCode_SecondaryDownArrow:
                if( !keyEvt.isRepeat )
                {
                    _selectedChoice++;
                    id<ICGConversationNode> currNode = self.currentConversationNode;
                    if( _selectedChoice > currNode.choices.count && _selectedChoice != NSUIntegerMax )
                    {
                        _selectedChoice = currNode.choices.count;    // Make sure pressing "up" immediately shows selection again and user doesn't have to press 3 times to get it back after 3 downs.
                    }
                    else
                        [self setNeedsDisplay: YES];
                }
                break;
            
            case ICGGameKeyCode_SecondaryInteract:
            case ICGGameKeyCode_TertiaryInteract:
                if( !keyEvt.isRepeat )
                {
                    id<ICGConversationNode> currNode = self.currentConversationNode;
                    if( _selectedChoice < currNode.choices.count )
                    {
                        [self triggerConversationChoice: currNode.choices[_selectedChoice] ];
                    }
                }
                break;
            
            default:
                if( !keyEvt.isRepeat )  // Don't keep beeping.
                    NSBeep();
                break;
        }
    }
}


-(void) handleGameKeyUp: (ICGGameKeyEvent*)keyEvt
{
    //NSLog(@"Key %ld released", keyEvt.keyCode);

    if( self.currentConversationNode == nil )
    {
        
    }
    else
    {
    
    }
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
    return [self.player moveByX: x y: y collidingWithItems: self.items];
}


-(void) moveLeft
{
    [self moveByX: -self.player.stepSize y: 0];
}


-(void) moveRight
{
    [self moveByX: self.player.stepSize y: 0];
}


-(void) moveUp
{
    [self moveByX: 0 y: self.player.stepSize];
}


-(void) moveDown
{
    [self moveByX: 0 y: -self.player.stepSize];
}


-(void) advanceMovePath: (NSTimer*)sender
{
    if( self.moveIndex >= self.movePath.count ) // Do this first, in case some nit hands us an empty path:
    {
        [sender invalidate];
        self.movePath = nil;
        self.moveTimer = nil;
    }

    ICGGamePathEntry* moveDist = self.movePath[self.moveIndex];
    if( [self moveByX: moveDist.x * self.player.stepSize y: moveDist.y * self.player.stepSize] != nil )
    {   // Collided with something, path probably outdated. Don't amble about after we've missed a step.
        [sender invalidate];
        self.movePath = nil;
        self.moveTimer = nil;
    }
    
    self.moveIndex = self.moveIndex +1; // If this was the last item, next timer fire will catch it.
}


-(void) setMovePath:(ICGGamePath *)movePath
{
    _movePath = movePath;
    _moveIndex = 0;
    
    if( self.moveTimer == nil )
    {
        self.moveTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(advanceMovePath:) userInfo: nil repeats: YES];
    }
}


-(BOOL) writeToFile: (NSString*)inFilePath
{
    NSData  *   theData = [NSKeyedArchiver archivedDataWithRootObject: @{ @"player": self.player, @"items": self.items, @"variables": self.variables }];
    return [theData writeToFile: inFilePath atomically: YES];
}


-(BOOL) readFromFile: (NSString*)inFilePath
{
    NSData*         theData = [NSData dataWithContentsOfFile: inFilePath];
    if( !theData )
        return NO;
    NSDictionary    *   dict = [NSKeyedUnarchiver unarchiveObjectWithData: theData];
    self.player = dict[@"player"];
    self.items = [dict[@"items"] mutableCopy];
    self.variables = [dict[@"variables"] mutableCopy];
    for( ICGGameItem* currItem in self.items )
    {
        currItem.owningView = self;
    }
    
    [self refreshItemDisplay];
    
    return YES;
}

@end
