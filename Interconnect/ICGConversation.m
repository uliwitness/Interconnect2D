//
//  ICGConversation.m
//  Interconnect
//
//  Created by Uli Kusterer on 28/08/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGConversation.h"


@interface ICGConversationNode : NSObject <ICGConversationNode>

@property (copy) NSString*          nodeIdentifier;         // Identifier used to refer to this conversation node in code.
@property (copy) NSString*          nodeMessage;    // Message to show above the choices. (E.g. instructions).
@property (strong) NSMutableArray*  choices;                // Array of ICGConversationChoice.
@property (weak) ICGConversation*   owner;

@end


NSString*   sChoiceTypeNames[ICGConversationChoiceType_INVALID] =
{
    @"Plain",
    @"MissionInfo",
    @"MissionAccept",
    @"MissionTurnIn"
};


@implementation ICGConversationChoice

+(instancetype)   plainChoice: (NSString*)inName message: (NSString*)inMessage
{
    ICGConversationChoice*    newChoice = [[self.class alloc] init];
    newChoice.choiceName = inName;
    newChoice.choiceMessage = inMessage;
    newChoice.conversationChoiceType = ICGConversationChoiceType_Plain;
    return newChoice;
}


+(instancetype)   missionInfoChoice: (NSString*)inName message: (NSString*)inMessage
{
    ICGConversationChoice*    newChoice = [[self.class alloc] init];
    newChoice.choiceName = inName;
    newChoice.choiceMessage = inMessage;
    newChoice.conversationChoiceType = ICGConversationChoiceType_MissionInfo;
    return newChoice;
}


+(instancetype)   missionAcceptChoice: (NSString*)inName message: (NSString*)inMessage
{
    ICGConversationChoice*    newChoice = [[self.class alloc] init];
    newChoice.choiceName = inName;
    newChoice.choiceMessage = inMessage;
    newChoice.conversationChoiceType = ICGConversationChoiceType_MissionAccept;
    return newChoice;
}

-(id)   initWithCoder: (NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        self.choiceName = [aDecoder decodeObjectForKey: @"ICGName"];
        self.choiceMessage = [aDecoder decodeObjectForKey: @"ICGMessage"];
        self.conversationChoiceType = [aDecoder decodeInt32ForKey: @"ICGType"];
        self.nextConversationNode = [aDecoder decodeObjectForKey: @"ICGNextNode"];
    }
    
    return self;
}


-(void) encodeWithCoder: (NSCoder *)aCoder
{
    [aCoder encodeObject: self.choiceName forKey: @"ICGName"];
    [aCoder encodeObject: self.choiceMessage forKey: @"ICGMessage"];
    [aCoder encodeInt32: self.conversationChoiceType forKey: @"ICGType"];
    [aCoder encodeObject: self.nextConversationNode forKey: @"ICGNextNode"];
}


-(NSString*)    description
{
    return [NSString stringWithFormat: @"%@ <%p> { name = \"%@\", msg = \"%@\", type = %@, next = %@ <%p> \"%@\" }", self.className, self, self.choiceName, self.choiceMessage, sChoiceTypeNames[self.conversationChoiceType], ((NSObject*)self.nextConversationNode).className, self.nextConversationNode, self.nextConversationNode.nodeIdentifier];
}

@end


@implementation ICGConversationNode

-(id)   init
{
    self = [super init];
    if( self )
    {
        self.choices = [NSMutableArray array];
    }
    return self;
}


-(id)   initWithCoder: (NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        self.nodeIdentifier = [aDecoder decodeObjectForKey: @"ICGIdentifier"];
        self.nodeMessage = [aDecoder decodeObjectForKey: @"ICGMessage"];
        self.choices = [aDecoder decodeObjectForKey: @"ICGChoices"];
    }
    
    return self;
}


-(void) encodeWithCoder: (NSCoder *)aCoder
{
    [aCoder encodeObject: self.nodeIdentifier forKey: @"ICGIdentifier"];
    [aCoder encodeObject: self.nodeMessage forKey: @"ICGMessage"];
    [aCoder encodeObject: self.choices forKey: @"ICGChoices"];
}


-(BOOL) hasMission
{
    for( ICGConversationChoice* currChoice in self.choices )
    {
        if( currChoice.conversationChoiceType == ICGConversationChoiceType_MissionInfo )
            return YES;
    }
    return NO;
}


-(BOOL) hasMissionTurnIn
{
    for( ICGConversationChoice* currChoice in self.choices )
    {
        if( currChoice.conversationChoiceType == ICGConversationChoiceType_MissionTurnIn )
            return YES;
    }
    return NO;
}


-(ICGConversationChoice*)   addPlainChoice: (NSString*)inName message: (NSString*)inMessage
{
    ICGConversationChoice*  newChoice = [ICGConversationChoice plainChoice: inName message: inMessage];
    newChoice.owner = self;
    [self.choices addObject: newChoice];
    return newChoice;
}


-(ICGConversationChoice*)   addMissionInfoChoice: (NSString*)inName message: (NSString*)inMessage
{
    ICGConversationChoice*  newChoice = [ICGConversationChoice missionInfoChoice: inName message: inMessage];
    newChoice.owner = self;
    [self.choices addObject: newChoice];
    return newChoice;
}


-(ICGConversationChoice*)   addMissionAcceptChoice: (NSString*)inName message: (NSString*)inMessage
{
    ICGConversationChoice*  newChoice = [ICGConversationChoice missionAcceptChoice: inName message: inMessage];
    newChoice.owner = self;
    [self.choices addObject: newChoice];
    return newChoice;
}


-(NSString*)    description
{
    return [NSString stringWithFormat: @"%@ <%p> { id = \"%@\", msg = \"%@\",\nchoices = %@ }", self.className, self, self.nodeIdentifier, self.nodeMessage, self.choices];
}

@end


@interface ICGConversation ()

@property (strong) NSMutableArray*          nodes;      // Array of ICGConversationNode that holds strong references to all our nodes.

@end


@implementation ICGConversation

-(id)   init
{
    self = [super init];
    if( self )
    {
        self.nodes = [NSMutableArray array];
    }
    
    return self;
}


-(id)   initWithCoder: (NSCoder *)aDecoder
{
    self = [super init];
    if( self )
    {
        self.nodes = [aDecoder decodeObjectForKey: @"ICGNodes"];
        self.firstNode = [aDecoder decodeObjectForKey: @"ICGFirstNode"];
    }
    
    return self;
}


-(void) encodeWithCoder: (NSCoder *)aCoder
{
    [aCoder encodeObject: self.nodes forKey: @"ICGNodes"];
    [aCoder encodeObject: self.firstNode forKey: @"ICGFirstNode"];
}


-(BOOL) hasMission
{
    return self.firstNode.hasMission;
}


-(BOOL) hasMissionTurnIn
{
    return self.firstNode.hasMissionTurnIn;
}


-(id<ICGConversationNode>) conversationNode
{
    ICGConversationNode*    newNode = [[ICGConversationNode alloc] init];
    newNode.owner = self;
    [self.nodes addObject: newNode];
    if( !self.firstNode )
        self.firstNode = newNode;
    return newNode;
}


-(id<ICGConversationNode>) conversationNode: (NSString*)inIdentifier message: (NSString*)inMessage
{
    ICGConversationNode*    newNode = [[ICGConversationNode alloc] init];
    newNode.nodeIdentifier = inIdentifier;
    newNode.nodeMessage = inMessage;
    newNode.owner = self;
    [self.nodes addObject: newNode];
    if( !self.firstNode )
        self.firstNode = newNode;
    return newNode;
}


-(NSString*)    description
{
    return [NSString stringWithFormat: @"%@ <%p> { first = %@ }", self.className, self, self.firstNode];
}

@end
