//
//  AYHAppDelegate.m
//  InAppWebHTTPServer
//
//  Created by AlimysoYang on 13-8-16.
//  Copyright (c) 2013年 AlimysoYang. All rights reserved.
//

#import "AYHAppDelegate.h"
#import "AYHViewController.h"


@implementation AYHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

//    
//    currentDataLength = 0;
//    

//    
//    [self initViews];
//

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    AYHViewController *viewController = [[AYHViewController alloc] init];
    self.window.rootViewController = viewController;
    viewController = nil;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



@end
