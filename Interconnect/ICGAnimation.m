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
    NSMutableArray*         frames = [NSMutableArray array];
    NSInteger               imgIdx = 0;
    NSImage*                img = [NSImage imageNamed: inName];
    if( !img )
        img = [NSImage imageNamed: [NSString stringWithFormat: @"%@%ld", inName, (long)++imgIdx]];
    while( img )
    {
        [frames addObject: img];
        img = [NSImage imageNamed: [NSString stringWithFormat: @"%@%ld", inName, (long)++imgIdx]];
    }
    ani.frames = frames;
    ani.name = inName;
    return ani;
}

@end
