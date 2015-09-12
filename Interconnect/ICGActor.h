//
//  ICGActor.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameItem.h"


@class ICGConversation;


@interface ICGActor : ICGGameItem <NSCoding>

@property (strong) ICGAnimation  *   leftWalkAnimation;
@property (strong) ICGAnimation  *   rightWalkAnimation;
@property (strong) ICGAnimation  *   upWalkAnimation;
@property (strong) ICGAnimation  *   downWalkAnimation;

@property (readonly) NSArray     *   inventoryItems;    // Array of ICGGameItem.

@property (strong,nonatomic) ICGConversation*  playerConversation;

-(void) addInventoryItem: (ICGGameItem *)obj;
-(void) removeInventoryItem: (ICGGameItem *)obj;

@end
