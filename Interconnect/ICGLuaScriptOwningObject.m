//
//  ICGLuaScriptOwningObject.m
//  Interconnect
//
//  Created by Uli Kusterer on 30/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGLuaScriptOwningObject.h"
#import "ICGGameView.h"
#import "ICGGameItem.h"
#import "ICGConversation.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"


@interface ICGLuaScriptOwningObject ()
{
    lua_State       *luaState;
}

@end



@implementation ICGLuaScriptOwningObject

-(id)   init
{
    self = [super init];
    if( self )
    {
        self.variables = [NSMutableDictionary new];
    }
    return self;
}


-(id)   initWithCoder: (NSCoder*)aDecoder
{
    self = [super init];
    if( self )
    {
        self.name = [aDecoder decodeObjectForKey: @"ICGName"];
        self.variables = [[aDecoder decodeObjectForKey: @"ICGVariables"] mutableCopy];
        self.script = [aDecoder decodeObjectForKey: @"ICGLuaScript"];
    }
    return self;
}


-(void) dealloc
{
    if( luaState )
        lua_close(luaState);	// Dispose of the script context.
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject: self.name forKey: @"ICGName"];
    [aCoder encodeObject: self.variables forKey: @"ICGVariables"];
    if( self.script )
        [aCoder encodeObject: self.script forKey: @"ICGLuaScript"];
}


-(NSArray*)     runScript: (NSString*)functionName
{
    return [self runScript: functionName withParams: nil];
}


-(NSArray*)     runScript: (NSString*)functionName withParams: (NSArray*)inParamStrings
{
    //NSLog( @"Calling %@ on %@", functionName, self );

    if( !luaState )
        [self compileScriptIfPossible];
    if( !luaState )
        return nil;
    
    //NSLog(@"\t%d stack elements before", lua_gettop(luaState));
    
    lua_getglobal( luaState, functionName.UTF8String );
    int     globalType = lua_type( luaState, -1 );
    if( globalType == LUA_TNIL )
    {
        //NSLog(@"\t%@ not implemented (NIL)", functionName);
        return nil;
    }
    int     pcount = (int)inParamStrings.count;
    for( NSString* currParam in inParamStrings )
    {
        if( [currParam respondsToSelector: @selector(pushIntoContext:)] )
            [(id)currParam pushIntoContext: luaState];
        else if( [currParam isKindOfClass: NSValue.class] && strcmp([(id)currParam objCType],"d") == 0 )
        {
            lua_pushnumber( luaState, [(id)currParam doubleValue] );
        }
        else if( [currParam isKindOfClass: NSValue.class] && strcmp([(id)currParam objCType],"f") == 0 )
        {
            lua_pushnumber( luaState, [(id)currParam floatValue] );
        }
        else if( [currParam isKindOfClass: NSValue.class] )
        {
            lua_pushinteger( luaState, [(id)currParam integerValue] );
        }
        else
            lua_pushstring( luaState, currParam.UTF8String );   // Push each param on the stack.
    }
    int s = lua_pcall( luaState, pcount, LUA_MULTRET, 0 );	// Tell Lua to expect pcount params & run it.
    if( s != 0 )
    {
        NSLog(@"Error running %@.%@: %s\n", self.name, functionName, lua_tostring(luaState, -1) );
        lua_pop(luaState, 1); // Remove error message from stack.
        return nil;
    }
    int numResults = lua_gettop(luaState);
    NSMutableArray *   array = [NSMutableArray arrayWithCapacity: numResults];
    //NSLog(@"\t%d stack elements after", numResults);
    for( int x = 0; x < numResults; x++ )
    {
        int currSlot = (numResults -x);
        int theType = lua_type(luaState, currSlot);
        if( theType == LUA_TNIL )
            [array addObject: [NSNull null]];
        else if( theType == LUA_TNUMBER )
            [array addObject: @(lua_tonumber( luaState, currSlot))];
        else if( theType == LUA_TBOOLEAN )
        {
            [array addObject: @(lua_toboolean(luaState, currSlot))];
        }
        else
        {
            const char* str = lua_tostring(luaState, currSlot);
            [array addObject: [NSString stringWithUTF8String: str]];
        }
    }
    lua_pop( luaState, numResults );
    return array;
}


-(void) setOwningView:(ICGGameView *)owningView
{
    _owningView = owningView;
    
    if( !luaState )
        [self compileScriptIfPossible];
}


-(void) setScript:(NSString *)script
{
    _script = script;
    
    [self compileScriptIfPossible];
}


-(void) compileScriptIfPossible
{
    if( self.script && self.owningView )
    {
        if( luaState )
            lua_close(luaState);	// Dispose of the script context.

        luaState = luaL_newstate();	// Create a context.
        luaL_openlibs(luaState);	// Load Lua standard library.

        // Load the file:
        const char* str = self.script.UTF8String;
        size_t      sz = strlen(str);
        int s = luaL_loadbuffer(luaState, str, sz, self.name.UTF8String);

        // Set up our 'globals' table:
        lua_newtable( luaState );   // Create object to hold globals.
        lua_newtable( luaState );   // Create metatable of object to hold globals.
        lua_pushlightuserdata( luaState, (__bridge void *)self );
        lua_pushcclosure( luaState, ICGGameItemGetGlobal, 1 );    // Wrap our C function in Lua.
        lua_setfield( luaState, -2, "__index" ); // Put the Lua-wrapped C function in the global as "__index".
        lua_pushlightuserdata( luaState, (__bridge void *)self );
        lua_pushcclosure( luaState, ICGGameItemSetGlobal, 1 );    // Wrap our C function in Lua.
        lua_setfield( luaState, -2, "__newindex" ); // Put the Lua-wrapped C function in the global as "__newindex".
        lua_setmetatable( luaState, -2 );   // Associate metatable with object holding globals.

        lua_setglobal( luaState, "global" );    // Put the object holding globals into a Lua global named "global".
        
        // Set up our 'variables' table:
        lua_newtable( luaState );   // Create object to hold variables.
        lua_newtable( luaState );   // Create metatable of object to hold variables.
        lua_pushlightuserdata( luaState, (__bridge void *)self );
        lua_pushcclosure( luaState, ICGGameItemGetVariable, 1 );    // Wrap our C function in Lua.
        lua_setfield( luaState, -2, "__index" ); // Put the Lua-wrapped C function in the global as "__index".
        lua_pushlightuserdata( luaState, (__bridge void *)self );
        lua_pushcclosure( luaState, ICGGameItemSetVariable, 1 );    // Wrap our C function in Lua.
        lua_setfield( luaState, -2, "__newindex" ); // Put the Lua-wrapped C function in the global as "__newindex".
        lua_setmetatable( luaState, -2 );   // Associate metatable with object holding me.

        lua_setglobal( luaState, "variables" );    // Put the object holding me into a Lua global named "variables".
        
        // Set up 'me' object:
        [self installIntoContext: luaState asGlobalNamed: "me"];

        // Set up our 'items' table:
        lua_newtable( luaState );   // Create object to hold me.
        lua_newtable( luaState );   // Create metatable of object to hold me.
        lua_pushlightuserdata( luaState, (__bridge void *)self );
        lua_pushcclosure( luaState, ICGGameItemsGetItem, 1 );    // Wrap our C function in Lua.
        lua_setfield( luaState, -2, "__index" ); // Put the Lua-wrapped C function in the global as "__index".
        lua_pushlightuserdata( luaState, (__bridge void *)self );
        lua_pushcclosure( luaState, ICGGameItemsSetItem, 1 );    // Wrap our C function in Lua.
        lua_setfield( luaState, -2, "__newindex" ); // Put the Lua-wrapped C function in the global as "__newindex".
        lua_setmetatable( luaState, -2 );   // Associate metatable with object holding me.

        lua_setglobal( luaState, "items" );    // Put the object holding me into a Lua global named "me".

        // Set the __index fallback of Lua's globals table so we can inject our objects as globals:
        lua_pushglobaltable( luaState );
        lua_newtable( luaState );   // Create metatable for object holding *Lua's* globals.
        lua_pushlightuserdata( luaState, (__bridge void *)self );
        lua_pushcclosure( luaState, ICGGameItemsGetItem, 1 );    // Wrap our C function in Lua.
        lua_setfield( luaState, -2, "__index" ); // Put the Lua-wrapped C function in the global as "__index".
        lua_setmetatable( luaState, -2 );   // Associate metatable with Lua's object holding globals.
        lua_pop( luaState, 1 ); // Pop the global table back off the stack now we've modified it, or it'll confuse the lua_pcall below.
        
        lua_pushcfunction( luaState, ICGGameItemNewConversation );
        lua_setglobal( luaState, "Conversation" );    // Put the function into a Lua global named "Conversation".

        if( s == 0 )
        {
            // Run it, with 0 params, (this creates the functions in their globals so we can call them)
            //  accepting an arbitrary number of return values.
            //	Last 0 is error handler Lua function's stack index, or 0 to ignore.
            s = lua_pcall(luaState, 0, LUA_MULTRET, 0);
        }

        // Was an error? Get error message off the stack and send it back:
        if( s != 0 )
        {
            NSLog(@"Compile error in %@: %s\n", self.name, lua_tostring(luaState, -1) );
            lua_pop(luaState, 1); // Remove error message from stack.
            
            NSLog(@"global.variables = %@", self.owningView.variables);
            NSLog(@"me.variables = %@", self.variables);
        }
    }
}


-(NSString*)    description
{
    return [NSString stringWithFormat: @"<%@: %p \"%@\">", self.className, self, self.name];
}


static NSMutableArray*  sConversations = nil;


static int ICGGameItemNewConversation( lua_State *luaState )
{
	int             numArgs = lua_gettop(luaState);    // Number of arguments.

    if( numArgs != 0 )
    {
        lua_pushstring(luaState, "Conversation() takes no arguments.");
        lua_error(luaState);
        return 0;
    }
    else
    {
        if( !sConversations )
            sConversations = [NSMutableArray array];
        ICGConversation*    convo = [[ICGConversation alloc] init];
        [sConversations addObject: convo];
        [convo pushIntoContext: luaState];
    }

	return 1;   // Number of results.
}


static int ICGGameItemSetGlobal( lua_State *luaState )
{
	int             numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGGameItem*	self = (__bridge ICGGameItem*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 3 )
    {
        lua_pushstring(luaState, "__newindex takes 3 arguments.");
        lua_error(luaState);
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        NSString    *   value = [NSString stringWithUTF8String: lua_tostring( luaState, 3 )];
        self.owningView.variables[ key ] = value;
    }

	return 0;   // Number of results.
}


static int ICGGameItemGetGlobal( lua_State *luaState )
{
	int             numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGGameItem*	self = (__bridge ICGGameItem*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 2 )
    {
        lua_pushstring(luaState, "__index takes 2 arguments.");
        lua_error(luaState);
        return 0;
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        NSString    *   value = self.owningView.variables[ key ];
        lua_pushstring( luaState, [value UTF8String] );
    }

	return 1;   // Number of results.
}


static int ICGGameItemSetVariable( lua_State *luaState )
{
	int                         numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGLuaScriptOwningObject*	self = (__bridge ICGLuaScriptOwningObject*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 3 )
    {
        lua_pushstring(luaState, "__newindex takes 3 arguments.");
        lua_error(luaState);
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        NSString    *   value = [NSString stringWithUTF8String: lua_tostring( luaState, 3 )];
        self.variables[ key ] = value;
    }

	return 0;   // Number of results.
}


static int ICGGameItemGetVariable( lua_State *luaState )
{
	int                         numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGLuaScriptOwningObject*	self = (__bridge ICGLuaScriptOwningObject*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 2 )
    {
        lua_pushstring(luaState, "__index takes 2 arguments.");
        lua_error(luaState);
        return 0;
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        NSString    *   value = self.variables[ key ];
        
        lua_pushstring( luaState, [value UTF8String] );
    }

	return 1;   // Number of results.
}


static int ICGGameItemsSetItem( lua_State *luaState )
{
	int             numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGLuaScriptOwningObject*	self = (__bridge ICGLuaScriptOwningObject*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 3 )
    {
        lua_pushstring(luaState, "__newindex takes 3 arguments.");
        lua_error(luaState);
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        NSString    *   value = [NSString stringWithUTF8String: lua_tostring( luaState, 3 )];
        NSLog( @"Script attempted to set %@ on %@.%@.", value, self, key );
        lua_pushstring(luaState, "The 'items' table can only be read.");
        lua_error(luaState);
    }

	return 0;   // Number of results.
}


static int ICGGameItemsGetItem( lua_State *luaState )
{
	int                         numArgs = lua_gettop(luaState);    // Number of arguments.
    ICGLuaScriptOwningObject*	self = (__bridge ICGLuaScriptOwningObject*) lua_touserdata( luaState, lua_upvalueindex(1) );

    if( numArgs != 2 )
    {
        lua_pushstring(luaState, "__index takes 2 arguments.");
        lua_error(luaState);
        return 0;
    }
    else
    {
        NSString    *   key = [NSString stringWithUTF8String: lua_tostring( luaState, 2 )];
        ICGGameItem *   value = nil;
        for( ICGGameItem* obj in self.owningView.items )
        {
            if( [obj.name caseInsensitiveCompare: key] == NSOrderedSame )
            {
                value = obj;
                break;
            }
        }
        
        if( value )
            [value pushIntoContext: luaState];
        else
        {
            lua_pushnil( luaState );    // Otherwise unimplemented functions never end up reported as NIL and are always errors, and clients would have to provide empty implementations of all of them.
        }
    }

	return 1;   // Number of results.
}

@end
