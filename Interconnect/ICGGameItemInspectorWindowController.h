//
//  ICGGameItemInspectorWindowController.h
//  Interconnect
//
//  Created by Uli Kusterer on 02/09/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ICGGameItem;


@interface ICGGameItemInspectorWindowController : NSWindowController <NSTableViewDataSource,NSTableViewDelegate>

@property (weak) IBOutlet NSTableView*  propertiesTable;

+(instancetype) sharedInspectorWindowController;

-(void) reflectItem: (ICGGameItem*)theItem;

@end
