//
//  ICGAnimation.h
//  Interconnect
//
//  Created by Uli Kusterer on 22/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ICGAnimation : NSObject

@property (copy) NSString*      name;
@property (strong) NSArray*     frames;

+(instancetype) animationNamed: (NSString*)inName;

@end
