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

#include <objc/runtime.h>



    static void ICGLuaStackDump (lua_State *L) {
      int i;
      int top = lua_gettop(L);
      for (i = 1; i <= top; i++) {  /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {
    
          case LUA_TSTRING:  /* strings */
            printf("%d: `%s'\n", i, lua_tostring(L, i));
            break;
    
          case LUA_TBOOLEAN:  /* booleans */
            printf(lua_toboolean(L, i) ? "%d: true\n" : "%d: false\n", i);
            break;
    
          case LUA_TNUMBER:  /* numbers */
            printf("%d: %g\n", i, lua_tonumber(L, i));
            break;
    
          default:  /* other values */
            printf("%d: %s\n", i, lua_typename(L, t));
            break;
    
        }
      }
      printf("\n");  /* end the listing */
    }



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
        key = [key stringByReplacingOccurrencesOfString: @"_" withString: @":"];
        
        if( class_getProperty( self.class, key.UTF8String ) != NULL )
        {
            id  theVal = [self valueForKey: key];
            if( [theVal respondsToSelector: @selector(stringValue)] )
                theVal = [theVal stringValue];
            lua_pushstring( luaState, [theVal UTF8String] );
        }
        else
        {
            if( [self respondsToSelector: NSSelectorFromString(key)] )
            {
                lua_pushlightuserdata( luaState, (__bridge void *)self );
                lua_pushstring( luaState, key.UTF8String );
                lua_pushcclosure( luaState, ICGLuaExposedObjectCallMethod, 2);
            }
            else if( [key isEqualToString: @"::objc:object"] )  // __objc_object after colons have been inserted.
                lua_pushlightuserdata( luaState, (__bridge void *)self );
            else
                lua_pushnil( luaState );
        }
    }

	return 1;   // Number of results.
}


static int ICGLuaExposedObjectCallMethod( lua_State *luaState )
{
	int                     numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGLuaExposedObject*	self = (__bridge ICGLuaExposedObject*) lua_touserdata( luaState, lua_upvalueindex(1) );

    NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, lua_upvalueindex(2) )];
    SEL             methodName = NSSelectorFromString(key);
    NSMethodSignature*  sig = [self methodSignatureForSelector: methodName];
    NSInvocation*   inv = [NSInvocation invocationWithMethodSignature: sig];
    [inv retainArguments];
    inv.target = self;
    inv.selector = methodName;
    
    if( numArgs != (sig.numberOfArguments -2) ) // -2 because we ignore self and _cmd (method name).
    {
        lua_pushfstring(luaState, "ObjC method %s takes %d parameters, only got %d", key.UTF8String, sig.numberOfArguments -2, numArgs);
        lua_error(luaState);
        return 0;
    }
    
    for( int currArgIdx = 1; currArgIdx <= numArgs; currArgIdx++ )
    {
        const char* argType = [sig getArgumentTypeAtIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
        if( lua_type(luaState,currArgIdx) == LUA_TTABLE && strcmp(argType, "@") == 0 )
        {
            lua_getfield( luaState, currArgIdx, "__objc_object" );
            id  theObject = (__bridge id) lua_touserdata( luaState, -1 );
            [inv setArgument: &theObject atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
        }
        else if( lua_type(luaState,currArgIdx) == LUA_TTABLE && strcmp(argType, "{CGPoint=dd}") == 0 )
        {
            NSPoint     pos = {0,0};
            lua_getfield( luaState, currArgIdx, "x" );
            pos.x = lua_tonumber( luaState, -1 );
            lua_getfield( luaState, currArgIdx, "y" );
            pos.y = lua_tonumber( luaState, -1 );
            [inv setArgument: &pos atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
        }
        else if( lua_type(luaState,currArgIdx) == LUA_TTABLE && strcmp(argType, "{CGSize=dd}") == 0 )
        {
            NSPoint     pos = {0,0};
            lua_getfield( luaState, currArgIdx, "width" );
            pos.x = lua_tonumber( luaState, -1 );
            lua_getfield( luaState, currArgIdx, "height" );
            pos.y = lua_tonumber( luaState, -1 );
            [inv setArgument: &pos atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
        }
        else if( lua_type(luaState,currArgIdx) == LUA_TNUMBER )
        {
            if( strcmp(argType,"i") == 0 )
            {
                int     theNumber = lua_tonumber( luaState, currArgIdx );
                [inv setArgument: &theNumber atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
            }
            else if( strcmp(argType,"I") == 0 )
            {
                int     theNumber = lua_tonumber( luaState, currArgIdx );
                [inv setArgument: &theNumber atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
            }
            else if( strcmp(argType,"q") == 0 )
            {
                long     theNumber = lua_tonumber( luaState, currArgIdx );
                [inv setArgument: &theNumber atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
            }
            else if( strcmp(argType,"Q") == 0 )
            {
                unsigned long     theNumber = lua_tonumber( luaState, currArgIdx );
                [inv setArgument: &theNumber atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
            }
            else if( strcmp(argType,"f") == 0 )
            {
                float     theNumber = lua_tonumber( luaState, currArgIdx );
                [inv setArgument: &theNumber atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
            }
            else if( strcmp(argType,"d") == 0 )
            {
                double     theNumber = lua_tonumber( luaState, currArgIdx );
                [inv setArgument: &theNumber atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
            }
            else
            {
                lua_pushfstring(luaState, "ObjC method %s argument %d should be of @encoded type %s", key.UTF8String, currArgIdx, argType);
                lua_error(luaState);
                return 0;
            }
        }
        else if( lua_type(luaState,currArgIdx) == LUA_TBOOLEAN && strcmp(argType, "c") == 0 )
        {
            BOOL    theBool = lua_toboolean( luaState, currArgIdx );
            [inv setArgument: &theBool atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
        }
        else if( lua_type(luaState,currArgIdx) == LUA_TSTRING && strcmp(argType, "@") == 0 )
        {
            const char  * currParamCStr = lua_tostring( luaState, currArgIdx );
            NSString    * currParamStr = [NSString stringWithUTF8String: currParamCStr];
            [inv setArgument: &currParamStr atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
        }
        else if( lua_type(luaState,currArgIdx) == LUA_TSTRING && (strcmp(argType, "r*") == 0 || strcmp(argType, "*") == 0) )    // const char* or char*
        {
            const char  * currParamCStr = lua_tostring( luaState, currArgIdx );
            [inv setArgument: &currParamCStr atIndex: currArgIdx +1];    // index is 0-based, but need to skip self and _cmd (method name).
        }
        else
        {
            lua_pushfstring(luaState, "ObjC method %s argument %d should be of @encoded type %s", key.UTF8String, currArgIdx, argType);
            lua_error(luaState);
            return 0;
        }
    }
    
    [inv invoke];
    
	return 0;   // Number of results.
}

@end
