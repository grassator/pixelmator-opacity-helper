//
//  DKAppDelegate.h
//  Pixelmator Opacity Helper
//
//  Created by Dmitriy Kubyshkin on 10/24/13.
//  Copyright (c) 2013 Dmitriy Kubyshkin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DKOpacityController.h"

@interface DKAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusBar;
@property DKOpacityController *opacityController;

@end
