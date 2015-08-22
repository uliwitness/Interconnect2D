//
//  ICGGameTool.m
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameTool.h"
#import "ICGGameItem.h"


@implementation ICGGameTool

-(id)   init
{
    self = [super init];
    if( self )
    {
        self.toolDistanceLimit = 30.0;
    }
    
    return self;
}


-(id)   initWithCoder: (NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        self.toolDistanceLimit = [aDecoder decodeDoubleForKey: @"ICGToolDistanceLimit"];
        self.wielder = [aDecoder decodeObjectForKey: @"ICGWielder"];
    }
    
    return self;
}


-(void) encodeWithCoder: (NSCoder *)aCoder
{
    [aCoder encodeDouble: self.toolDistanceLimit forKey: @"ICGToolDistanceLimit"];
    [aCoder encodeObject: self.wielder forKey: @"ICGWielder"];
}


-(BOOL) interactWithItem: (ICGGameItem*)otherItem
{
    //NSLog( @"%@ interacting with %@", self.wielder.image.name, otherItem.image.name );
    
    otherItem.balloonText = @"I feel very interacted!\nHow about you?";
    [otherItem performSelector: @selector(setBalloonText:) withObject: nil afterDelay: 2.0];
    
    return YES;
}


-(NSArray*) filterNearbyItems: (NSArray*)nearbyItems
{
    NSMutableArray* filteredItems = [NSMutableArray array];
    CGFloat         toolDistanceLimit = self.toolDistanceLimit;
    for( ICGGameItem* currItem in nearbyItems )
    {
        CGFloat     distance = [self.wielder distanceToItem: currItem];
        if( distance < toolDistanceLimit )
        {
            [filteredItems addObject: currItem];
        }
    }
    return filteredItems;
}

@end

