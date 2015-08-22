//
//  ICGGameView.h
//  Interconnect
//
//  Created by Uli Kusterer on 21/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ICGGameItem;
@class ICGGameTool;
@class ICGGameKeyEvent;
@class ICGActor;

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
    ICGGameKeyCode_SwitchTool = 'q',
    ICGGameKeyCode_Talk = 't',
    ICGGameKeyCode_Tool1 = '1',
    ICGGameKeyCode_Tool2 = '2',
    ICGGameKeyCode_Tool3 = '3',
    ICGGameKeyCode_Tool4 = '4',
    ICGGameKeyCode_Tool5 = '5',
    ICGGameKeyCode_Tool6 = '6',
    ICGGameKeyCode_Tool7 = '7',
    ICGGameKeyCode_Tool8 = '8',
    ICGGameKeyCode_Tool9 = '9',
    ICGGameKeyCode_Tool0 = '0',
};


@interface ICGGameView : NSView

@property (retain,nonatomic) NSMutableArray*        items;
@property (retain,nonatomic) ICGGameItem*           player;

-(void) interactWithTool: (ICGGameTool*)inTool;
-(void) switchTool;
-(ICGGameItem*) moveByX: (CGFloat)x y: (CGFloat)y;

-(void) handleGameKeyDown: (ICGGameKeyEvent*)keyEvt;
-(void) handleGameKeyUp: (ICGGameKeyEvent*)keyEvt;

-(void) refreshItemDisplay;

-(BOOL) writeToFile: (NSString*)inFilePath;
-(BOOL) readFromFile: (NSString*)inFilePath;

@end


@interface ICGGameKeyEvent : NSObject

@property ICGGameKeyCode    keyCode;
@property BOOL              isRepeat;

@end


