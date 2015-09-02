//
//  ICGGameItemInspectorWindowController.m
//  Interconnect
//
//  Created by Uli Kusterer on 02/09/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "ICGGameItemInspectorWindowController.h"
#import "ICGGameItem.h"


static ICGGameItemInspectorWindowController*    sSharedGameItemController = nil;


@interface ICGGameItemInspectorWindowController ()

@property (weak) ICGGameItem*       reflectedItem;
@property (strong) NSArray*         properties;

@end

@implementation ICGGameItemInspectorWindowController

+(instancetype) sharedInspectorWindowController
{
    if( !sSharedGameItemController )
    {
        sSharedGameItemController = [[self.class alloc] initWithWindowNibName: @"ICGGameItemInspectorWindowController"];
    }
    return sSharedGameItemController;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self.propertiesTable reloadData];
}


-(void) reflectItem: (ICGGameItem *)theItem
{
    self.properties = @[ @"name", @"balloonText", @"script" ];
    self.reflectedItem = theItem;
    
    [self.propertiesTable reloadData];
}


-(NSInteger)    numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.properties.count;
}


-(id)   tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( [tableColumn.identifier isEqualToString: @"label"] )
        return self.properties[row];
    else
        return [self.reflectedItem valueForKey: self.properties[row]];
}


-(void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( [tableColumn.identifier isEqualToString: @"value"] )
        [self.reflectedItem setValue: object forKey: self.properties[row]];
}


-(CGFloat)   tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    CGFloat rowHeight = self.propertiesTable.rowHeight;
    if( [self.properties[row] isEqualToString: @"script"] )
    {
        NSInteger   numLines = [self.reflectedItem.script componentsSeparatedByString: @"\n"].count;
        NSFont      *cellFont = [[self.propertiesTable tableColumnWithIdentifier: @"value"].dataCell font];
        CGFloat     textLineHeight = cellFont.ascender - cellFont.descender + cellFont.leading;
        if( numLines > 1 )
            rowHeight += textLineHeight * (numLines -1);
    }
    
    return rowHeight;
}

@end
