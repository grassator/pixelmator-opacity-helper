//
//  DKAppDelegate.m
//  Pixelmator Opacity Helper
//
//  Created by Dmitriy Kubyshkin on 10/24/13.
//  Copyright (c) 2013 Dmitriy Kubyshkin. All rights reserved.
//

#import "DKAppDelegate.h"

/*!
 From 10.9's AXUIElement.h in ApplicationServices.framework:
 
 @function AXIsProcessTrustedWithOptions
 @abstract Returns whether the current process is a trusted accessibility client.
 @param options A dictionary of options, or NULL to specify no options. The following options are available:
 
 KEY: kAXTrustedCheckOptionPrompt
 VALUE: ACFBooleanRef indicating whether the user will be informed if the current process is untrusted. This could be used, for example, on application startup to always warn a user if accessibility is not enabled for the current process. Prompting occurs asynchronously and does not affect the return value.
 
 @result Returns TRUE if the current process is a trusted accessibility client, FALSE if it is not.
 */
extern Boolean AXIsProcessTrustedWithOptions(CFDictionaryRef options) __attribute__((weak_import));
extern CFStringRef kAXTrustedCheckOptionPrompt __attribute__((weak_import));

@implementation DKAppDelegate

- (void) awakeFromNib {
  _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  
  // you can also set an image
  _statusBar.image = [NSImage imageNamed:@"statusicon.tif"];
  
  _statusBar.menu = _statusMenu;
  _statusBar.highlightMode = YES;
}

- (void)showAccessibilityApiWarningWithOSXTenNineOrNewer:(BOOL)isOSXTenNineOrNewer
{
  NSString * informationText;
  if(isOSXTenNineOrNewer) {
    informationText = @"Access can be granted in System Preferences. Please reopen Pixelmator Opacity Helper afterwards.";
  } else {
    informationText = @"Please click on \"access for assistive devices\" checkbox in System Preferences Universal Access pane and reopen Pixelmator Opacity Helper afterwards.";
  }
  NSAlert *alert = [NSAlert alertWithMessageText:@"Pixelmator Opacity Helper needs access to Accessibility APIs."
                                   defaultButton:@"Exit & Open System Preferences"
                                 alternateButton:@"Exit"
                                     otherButton:nil
                       informativeTextWithFormat:@""];
  [alert setInformativeText:informationText];
  [alert setAlertStyle:NSCriticalAlertStyle];
  
  // if user has chosen to go preferences
  if([alert runModal] == NSAlertDefaultReturn)
  {
    // execute applescript that opens preferences on appropriate pane
    NSString* path = [[NSBundle mainBundle] pathForResource:@"assistive" ofType:@"scpt"];
    NSURL* url = [NSURL fileURLWithPath:path];
    NSDictionary* errors = [NSDictionary dictionary];
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
    [appleScript executeAndReturnError:nil];
  }
  
  [NSApp terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // We first have to check if the Accessibility APIs are turned on.
  // If not, we have to tell the user to do it (they'll need to authenticate
  // to do it).  If you are an accessibility app (i.e., if you are getting
  // info about UI elements in other apps), the APIs won't work unless the
  // access for assitive decices is turned on.
  if (AXIsProcessTrustedWithOptions != NULL) { // OS X 10.9 or higher
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanFalse, kAXTrustedCheckOptionPrompt, nil];
    if (!AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options)) {
      [self showAccessibilityApiWarningWithOSXTenNineOrNewer: YES];
    }
  } else if (!AXAPIEnabled()) { // OS X 10.5-10.8
    [self showAccessibilityApiWarningWithOSXTenNineOrNewer: NO];
  }
  
  // Now we can start watching for keys
  _opacityController = [DKOpacityController new];
}


@end
