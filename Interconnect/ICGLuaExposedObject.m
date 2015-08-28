//
//  ICGLuaExposedObject.m
//  Interconnect
//
//  Created by Uli Kusterer on 24/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGLuaExposedObject.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"



@implementation ICGLuaExposedObject

-(void) pushIntoContext: (lua_State*)luaState
{
    lua_newtable( luaState );   // Create object to hold globals.
    lua_newtable( luaState );   // Create metatable of object to hold globals.
    lua_pushlightuserdata( luaState, (__bridge void *)self );
    lua_pushcclosure( luaState, ICGLuaExposedObjectGetProperty, 1 );    // Wrap our C function in Lua.
    lua_setfield( luaState, -2, "__index" ); // Put the Lua-wrapped C function in the global as "__index".
    lua_pushlightuserdata( luaState, (__bridge void *)self );
    lua_pushcclosure( luaState, ICGLuaExposedObjectSetProperty, 1 );    // Wrap our C function in Lua.
    lua_setfield( luaState, -2, "__newindex" ); // Put the Lua-wrapped C function in the global as "__newindex".
    lua_setmetatable( luaState, -2 );   // Associate metatable with object holding globals.
}


-(void) installIntoContext: (lua_State*)luaState asGlobalNamed: (const char*)inName
{
    [self pushIntoContext: luaState];

    lua_setglobal( luaState, inName );    // Put the object holding globals into a Lua global named "global".
}


static int ICGLuaExposedObjectSetProperty( lua_State *luaState )
{
	int                     numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGLuaExposedObject*	self = (__bridge ICGLuaExposedObject*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 3 )
    {
        lua_pushstring(luaState, "__newindex takes 3 arguments.");
        lua_error(luaState);
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        NSString    *   value = [NSString stringWithUTF8String: lua_tostring( luaState, 3 )];
        @try {
            [self setValue: value forKey: key];
        }
        @catch (NSException *exception) {
            lua_pushstring(luaState, "Error setting value. Probably the wrong type?");
            lua_error(luaState);
        }
    }

	return 0;   // Number of results.
}


static int ICGLuaExposedObjectGetProperty( lua_State *luaState )
{
	int                     numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGLuaExposedObject*	self = (__bridge ICGLuaExposedObject*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 2 )
    {
        lua_pushstring(luaState, "__index takes 2 arguments.");
        lua_error(luaState);
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        
        id  theVal = [self valueForKey: key];
        if( [theVal respondsToSelector: @selector(stringValue)] )
            theVal = [theVal stringValue];
        lua_pushstring( luaState, [theVal UTF8String] );
    }

	return 1;   // Number of results.
}

@end
