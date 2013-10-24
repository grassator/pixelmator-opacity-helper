//
//  DKAppDelegate.m
//  Pixelmator Opacity Helper
//
//  Created by Dmitriy Kubyshkin on 10/24/13.
//  Copyright (c) 2013 Dmitriy Kubyshkin. All rights reserved.
//

#import "DKAppDelegate.h"

@implementation DKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // Initializing some values
  _lastValue = -1;
  
  // Making unsafe reference so we can use it an block without memory leak
  DKAppDelegate * __unsafe_unretained app = self;
  
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
  
}

// Here we convert pressed number to a precentage value
// taking into account consecutive presses that allow
// for more precise control
- (NSString*)getNewPercentageValue:(NSInteger) value
{
  NSString *newPercentageValue;
  
  if (_lastTimePressed && _lastValue != -1 &&
      [[NSDate date] timeIntervalSinceDate:_lastTimePressed] < 1.0)
  {
    if(value == 0 && _lastValue == 0)
    {
      newPercentageValue = @"0%";
    }
    else
    {
      newPercentageValue = [NSString stringWithFormat:@"%ld%ld%%", _lastValue, value];
    }
    value = -1;
  }
  else
  {
    if(value == 0)
    {
      newPercentageValue = @"100%";
    }
    else
    {
      newPercentageValue = [NSString stringWithFormat:@"%ld0%%", value];
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
  NSLog(@"%@", newPercentageValue);
}

- (void)dealloc
{
  [NSEvent removeMonitor:self.eventHandler];
}

@end
