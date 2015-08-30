//
//  ICGLuaScriptOwningObject.h
//  Interconnect
//
//  Created by Uli Kusterer on 30/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGLuaExposedObject.h"


@class ICGGameView;


@interface ICGLuaScriptOwningObject : ICGLuaExposedObject <NSCoding>

@property (copy,nonatomic) NSString*                name;
@property (copy,nonatomic) NSString*                script;
@property (weak,nonatomic) ICGGameView*             owningView;         // Subclassers only. The view in which we're being displayed.
@property (strong,nonatomic) NSMutableDictionary*   variables;          // Variables game logic can use to remember state of this item.

-(BOOL)     runScript: (NSString*)functionName;
-(BOOL)     runScript: (NSString*)functionName withParams: (NSArray*)inParamStrings;

@end
