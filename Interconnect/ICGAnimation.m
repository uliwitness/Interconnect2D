//
//  ICGAnimation.m
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGAnimation.h"

@implementation ICGAnimation

+(instancetype) animationNamed: (NSString*)inName
{
    ICGAnimation*           ani = [ICGAnimation new];
    ani.name = inName;
    [ani loadFrames];
    return ani;
}


-(id)   initWithCoder: (NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        self.name = [aDecoder decodeObjectForKey: @"ICGName"];
        [self loadFrames];
    }
    
    return self;
}


-(void) encodeWithCoder: (NSCoder *)aCoder
{
    [aCoder encodeObject: self.name forKey: @"ICGName"];
}


-(void) loadFrames
{
    NSMutableArray*         frames = [NSMutableArray array];
    NSInteger               imgIdx = 0;
    NSImage*                img = [NSImage imageNamed: self.name];
    if( !img )
        img = [NSImage imageNamed: [NSString stringWithFormat: @"%@%ld", self.name, (long)++imgIdx]];
    while( img )
    {
        [frames addObject: img];
        img = [NSImage imageNamed: [NSString stringWithFormat: @"%@%ld", self.name, (long)++imgIdx]];
    }
    self.frames = frames;
}

@end
