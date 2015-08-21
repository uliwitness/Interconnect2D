//
//  ICGGameTool.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ICGGameItem;


@interface ICGGameTool : NSObject

@property (assign) CGFloat      toolDistanceLimit;
@property (weak) ICGGameItem*   wielder;

-(BOOL) interactWithItem: (ICGGameItem*)otherItem;
-(NSArray*) filterNearbyItems: (NSArray*)nearbyItems;

@end


