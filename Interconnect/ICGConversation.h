//
//  ICGConversation.h
//  Interconnect
//
//  Created by Uli Kusterer on 28/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ICGActor;


typedef NS_ENUM(uint32_t, ICGConversationChoiceType)
{
    ICGConversationChoiceType_Plain,          // Nothing special, just a thing the player can say.
    ICGConversationChoiceType_MissionInfo,    // Show info about a mission, where you can accept it.
    ICGConversationChoiceType_MissionAccept,  // Actually accept a mission.
    ICGConversationChoiceType_MissionTurnIn,  // Turn in a mission (i.e. end it and get rewards).
    ICGConversationChoiceType_INVALID         // Used for "number of choice types" internally. Must be last.
};


@class ICGConversation;
@class ICGGameItem;
@protocol ICGConversationNode;


// One choice in a conversation node:

@interface ICGConversationChoice : NSObject <NSCoding>

+(instancetype)   plainChoice: (NSString*)inName message: (NSString*)inMessage;
+(instancetype)   missionInfoChoice: (NSString*)inName message: (NSString*)inMessage;
+(instancetype)   missionAcceptChoice: (NSString*)inName message: (NSString*)inMessage;

@property (copy) NSString*                      choiceName;     // Name of this choice, shown on the button.
@property (copy) NSString*                      choiceMessage;  // Message to display when the user chooses this button.
@property (assign) ICGConversationChoiceType    conversationChoiceType;
@property (weak) id<ICGConversationNode>        nextConversationNode;   // Node to go to when this choice is picked.
@property (weak) id<ICGConversationNode>        owner;          // Node in which this is listed.

@end


// One "page" in the conversation, i.e. instructions or a message and choices
//  that the user can pick to advance to the node or trigger actions.
// Create an object that conforms to this type by asking an ICGConversation
//  object for one using its -conversationNode method.

@protocol ICGConversationNode <NSObject,NSCoding>

@property (copy) NSString*          nodeIdentifier;         // Identifier used to refer to this conversation node in code.
@property (copy) NSString*          nodeMessage;            // Message to show above the choices. (E.g. instructions).
@property (readonly) NSArray*       choices;                // Array of ICGConversationChoice.
@property (readonly) BOOL           hasMission;             // Contains ICGConversationChoiceType_MissionInfo choices.
@property (readonly) BOOL           hasMissionTurnIn;       // Contains ICGConversationChoiceType_MissionTurnIn choices.
@property (weak) ICGConversation*   owner;                  // Conversation containing this node.

-(ICGConversationChoice*)   addPlainChoice: (NSString*)inName message: (NSString*)inMessage;
-(ICGConversationChoice*)   addMissionInfoChoice: (NSString*)inName message: (NSString*)inMessage;
-(ICGConversationChoice*)   addMissionAcceptChoice: (NSString*)inName message: (NSString*)inMessage;

@end


// An entire conversation that can be attached to an actor or triggered out-of-line:

@interface ICGConversation : NSObject <NSCoding>

@property (strong) id<ICGConversationNode>  firstNode;  // The ICGConversationNode at which we should start. Defaults to the first node created using -conversationNode.
@property (readonly) BOOL                   hasMission;     // Contains mission info choices in the firstNode;
@property (readonly) BOOL                   hasMissionTurnIn;       // Contains ICGConversationChoiceType_MissionTurnIn choices.
@property (weak) ICGActor*                  owner;

-(id<ICGConversationNode>) conversationNode;   // Create a new ICGConversationNode associated with this conversation.
-(id<ICGConversationNode>) conversationNode: (NSString*)inIdentifier message: (NSString*)inMessage;

@end

