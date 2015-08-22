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


-(BOOL) interactWithItem: (ICGGameItem*)otherItem
{
    NSLog( @"%@ interacting with %@", self.wielder.image.name, otherItem.image.name );
    
    otherItem.balloonText = @"I feel very interacted!";
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

