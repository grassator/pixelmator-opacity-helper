//
//  DKOpacityController.m
//  Pixelmator Opacity Helper
//
//  Created by Dmitriy Kubyshkin on 10/24/13.
//  Copyright (c) 2013 Dmitriy Kubyshkin. All rights reserved.
//

#import "DKOpacityController.h"
#import "UIElementUtilities.h"

@implementation DKOpacityController

- (id) init
{
  if (!(self = [super init])) return nil;
  
  _lastValue = -1;
  
  // Making unsafe reference so we can use it an block without memory leak
  DKOpacityController * __unsafe_unretained app = self;
  
  // Listening for global key down events instead of local since we want
  // to do something while other applciation (Pixelmator) is active
  _eventHandler = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask
                                                         handler:^(NSEvent *event)
                   {
                     // Filtering out numers based on key codes which should be pretty fast
                     ushort code = [event keyCode];
                     if (
                         (code >= 18 && code <= 29 && code != 27 && code != 24) || // regular number keys
                         (code >= 82 && code <= 92 && code != 90) // numpad keys
                         )
                     {
                       [app adjustPixelmatorOpacity:[[event characters] integerValue]];
                     }
                   }];
  return self;
}

// Here we convert pressed number to a precentage value
// taking into account consecutive presses that allow
// for more precise control
- (NSString*)getNewPercentageValue:(NSInteger) value
{
  NSString *newPercentageValue;
  
  // if consecutive inputs like "2", "5"
  if (_lastTimePressed && _lastValue != -1 &&
      [[NSDate date] timeIntervalSinceDate:_lastTimePressed] < 1.0)
  {
    if(_lastValue == 0) {
      if (value == 0) {
        newPercentageValue = @"0";
      } else {
        newPercentageValue = [NSString stringWithFormat:@"%ld", value];
      }
    } else {
      newPercentageValue = [NSString stringWithFormat:@"%ld%ld", _lastValue, value];
    }
    value = -1;
  } else {
    if(value == 0) {
      newPercentageValue = @"100";
    } else {
      newPercentageValue = [NSString stringWithFormat:@"%ld0", value];
    }
  }
  
  // saving values for next iteration
  _lastValue = value;
  _lastTimePressed = [NSDate date];
  
  return newPercentageValue;
}


- (void)adjustPixelmatorOpacity:(NSInteger) value
{
  NSString *newPercentageValue = [self getNewPercentageValue:value];
  AXUIElementRef opacitySlider = NULL;
  
  // Checking all open windows to see if Pixelmator is there
  for (NSMutableDictionary* entry in (__bridge NSArray*)CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID))
  {
    if([[entry objectForKey:(id)kCGWindowOwnerName] isEqualToString:@"Pixelmator"]) {
      // Getting accessibility reference to the app
      pid_t ownerPID = (pid_t)[[entry objectForKey:(id)kCGWindowOwnerPID] integerValue];
      AXUIElementRef appElement = AXUIElementCreateApplication(ownerPID);
      
      // Checking that the app is focused.
      if(![[UIElementUtilities valueOfAttribute:@"AXFrontmost" ofUIElement:appElement] boolValue]) return;
      
      // Trying to find a document window
      AXUIElementRef documentWindow = (__bridge AXUIElementRef)([UIElementUtilities valueOfAttribute:@"AXFocusedWindow" ofUIElement:appElement]);
      if(!documentWindow) return;
      
      // Trying to locate a child slider that has bounds [0 : 100] (%)
      NSArray *windowChildren = (NSArray *)[UIElementUtilities valueOfAttribute:@"AXChildren" ofUIElement:documentWindow];
      for (id child in windowChildren) {
        // First we check that it is a text field
        if(![(NSString *)[UIElementUtilities valueOfAttribute:@"AXRole" ofUIElement:(AXUIElementRef)child] isEqualToString:@"AXSlider"]) continue;
        
        // Now we check upper and lower bound
        if(100 != [[UIElementUtilities valueOfAttribute:@"AXMaxValue" ofUIElement:(AXUIElementRef)child] integerValue]) continue;
        if(  0 != [[UIElementUtilities valueOfAttribute:@"AXMinValue" ofUIElement:(AXUIElementRef)child] integerValue]) continue;
        
        // Saving a reference and ending our search
        opacitySlider = (__bridge AXUIElementRef)child;
        break;
      }
      
      break;
    }
  }
  
  if(opacitySlider) {
    [UIElementUtilities setStringValue:newPercentageValue forAttribute:@"AXValue" ofUIElement:opacitySlider];
    [UIElementUtilities performAction:@"AXConfirm" ofUIElement:opacitySlider];
  }
}


- (void)dealloc
{
  [NSEvent removeMonitor:self.eventHandler];
}

@end
