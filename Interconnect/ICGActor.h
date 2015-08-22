//
//  ICGActor.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameItem.h"

@interface ICGActor : ICGGameItem

@property (strong) NSArray  *   leftWalkAnimation;
@property (strong) NSArray  *   rightWalkAnimation;
@property (strong) NSArray  *   upWalkAnimation;
@property (strong) NSArray  *   downWalkAnimation;

@end
