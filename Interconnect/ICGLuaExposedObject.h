//
//  ICGLuaExposedObject.h
//  Interconnect
//
//  Created by Uli Kusterer on 24/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>

struct lua_State;

@interface ICGLuaExposedObject : NSObject

-(void) pushIntoContext: (struct lua_State*)luaState;
-(void) installIntoContext: (struct lua_State*)luaState asGlobalNamed: (const char*)inName;

@end
