//
//  ICGActor.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameItem.h"

@interface ICGActor : ICGGameItem <NSCoding>

@property (strong) ICGAnimation  *   leftWalkAnimation;
@property (strong) ICGAnimation  *   rightWalkAnimation;
@property (strong) ICGAnimation  *   upWalkAnimation;
@property (strong) ICGAnimation  *   downWalkAnimation;

@end
