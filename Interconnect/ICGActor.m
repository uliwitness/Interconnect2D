//
//  ICGActor.m
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGActor.h"
#import "ICGGameView.h"


@implementation ICGActor

-(id)   initWithCoder: (NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if( self )
    {
        self.leftWalkAnimation = [aDecoder decodeObjectForKey: @"ICGLeftWalkAnimation"];
        self.rightWalkAnimation = [aDecoder decodeObjectForKey: @"ICGRightWalkAnimation"];
        self.upWalkAnimation = [aDecoder decodeObjectForKey: @"ICGUpWalkAnimation"];
        self.downWalkAnimation = [aDecoder decodeObjectForKey: @"ICGDownWalkAnimation"];
    }
    
    return self;
}


-(void) encodeWithCoder: (NSCoder *)aCoder
{
    [super encodeWithCoder: aCoder];
    
    [aCoder encodeObject: self.leftWalkAnimation forKey: @"ICGLeftWalkAnimation"];
    [aCoder encodeObject: self.rightWalkAnimation forKey: @"ICGRightWalkAnimation"];
    [aCoder encodeObject: self.upWalkAnimation forKey: @"ICGUpWalkAnimation"];
    [aCoder encodeObject: self.downWalkAnimation forKey: @"ICGDownWalkAnimation"];
}


-(ICGGameItem*) moveByX: (CGFloat)x y: (CGFloat)y collidingWithItems: (NSArray*)items
{
    if( self.leftWalkAnimation && x < 0 )
    {
        if( self.animation != self.leftWalkAnimation )
            self.animation = self.leftWalkAnimation;
        else
            [self advanceAnimation];
    }
    else if( self.rightWalkAnimation && x > 0 )
    {
        if( self.animation != self.rightWalkAnimation )
            self.animation = self.rightWalkAnimation;
        else
            [self advanceAnimation];
    }
    else if( self.upWalkAnimation && y > 0 )
    {
        if( self.animation != self.upWalkAnimation )
            self.animation = self.upWalkAnimation;
        else
            [self advanceAnimation];
    }
    else if( self.downWalkAnimation && y < 0 )
    {
        if( self.animation != self.downWalkAnimation )
            self.animation = self.downWalkAnimation;
        else
            [self advanceAnimation];
    }
    
    return [super moveByX: x y: y collidingWithItems: items];
}

@end
