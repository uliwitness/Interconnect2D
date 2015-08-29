//
//  ICGGameToolTalk.m
//  Interconnect
//
//  Created by Uli Kusterer on 29/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameToolTalk.h"
#import "ICGGameItem.h"
#import "ICGConversation.h"
#import "ICGActor.h"
#import "ICGGameView.h"


@implementation ICGGameToolTalk

-(BOOL) interactWithItem: (ICGGameItem*)otherItem
{
    //NSLog( @"%@ interacting with %@", self.wielder.image.name, otherItem.image.name );
    
    otherItem.owningView.currentConversationNode = [(ICGActor*)otherItem playerConversation].firstNode;
    otherItem.owningView.currentConversation = [(ICGActor*)otherItem playerConversation];
    [otherItem performSelector: @selector(setBalloonText:) withObject: nil afterDelay: 2.0];
    
    return YES;
}


-(NSArray*) filterNearbyItems: (NSArray*)nearbyItems
{
    NSMutableArray* filteredItems = [NSMutableArray array];
    CGFloat         toolDistanceLimit = self.toolDistanceLimit;
    for( ICGGameItem* currItem in nearbyItems )
    {
        if( ![currItem respondsToSelector: @selector(playerConversation)]
            || [(ICGActor*)currItem playerConversation] == nil )
            continue;
        
        CGFloat     distance = [self.wielder distanceToItem: currItem];
        if( distance < toolDistanceLimit )
        {
            [filteredItems addObject: currItem];
        }
    }
    return filteredItems;
}

@end
