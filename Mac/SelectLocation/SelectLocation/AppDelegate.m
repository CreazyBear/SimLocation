//
//  AppDelegate.m
//  SelectLocation
//
//  Created by 熊伟 on 2019/9/7.
//  Copyright © 2019 熊伟. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.window = NSApp.keyWindow;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    
    if (!flag) {
        [self.window makeKeyAndOrderFront:self];
    }
    return YES;
}

@end
