//
//  ICGGameView.h
//  Interconnect
//
//  Created by Uli Kusterer on 21/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ICGGameItem;

@interface ICGGameView : NSView

@property (retain,nonatomic) NSMutableArray*        items;
@property (retain,nonatomic) ICGGameItem*           player;

@end
