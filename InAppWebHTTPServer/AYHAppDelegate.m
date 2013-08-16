//
//  AYHAppDelegate.m
//  InAppWebHTTPServer
//
//  Created by AlimysoYang on 13-8-16.
//  Copyright (c) 2013年 AlimysoYang. All rights reserved.
//

#import "AYHAppDelegate.h"
#import "HTTPServer.h"
#import "AYHTTPConnection.h"

#define GBUnit 1073741824
#define MBUnit 1048576
#define KBUnit 1024

@implementation AYHAppDelegate

- (void) uploadWithStart:(NSNotification *) notification
{
    UInt64 fileSize = [(NSNumber *)[notification.userInfo objectForKey:@"totalfilesize"] longLongValue];
    __block NSString *showFileSize = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (fileSize>GBUnit)
            showFileSize = [[NSString alloc] initWithFormat:@"/%.1fG", (CGFloat)fileSize / (CGFloat)GBUnit];
        if (fileSize>MBUnit && fileSize<=GBUnit)
            showFileSize = [[NSString alloc] initWithFormat:@"/%.1fMB", (CGFloat)fileSize / (CGFloat)MBUnit];
        else if (fileSize>KBUnit && fileSize<=MBUnit)
            showFileSize = [[NSString alloc] initWithFormat:@"/%lliKB", fileSize / KBUnit];
        else if (fileSize<=KBUnit)
            showFileSize = [[NSString alloc] initWithFormat:@"/%lliB", fileSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_lbFileSize setText:showFileSize];
            [_progressView setHidden:NO];
        });
    });
    showFileSize = nil;
}

- (void) uploadWithEnd:(NSNotification *) notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        currentDataLength = 0;
        [_progressView setHidden:YES];
        [_progressView setProgress:0.0];
        [_lbFileSize setText:@""];
        [_lbCurrentFileSize setText:@""];
    });
}

- (void) uploadWithDisconnect:(NSNotification *) notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        currentDataLength = 0;
        [_progressView setHidden:YES];
        [_progressView setProgress:0.0];
        [_lbFileSize setText:@""];
        [_lbCurrentFileSize setText:@""];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Upload data interrupt!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        alert = nil;
    });
}

- (void) uploading:(NSNotification *)notification
{
    float value = [(NSNumber *)[notification.userInfo objectForKey:@"progressvalue"] floatValue];
    currentDataLength += [(NSNumber *)[notification.userInfo objectForKey:@"cureentvaluelength"] intValue];
    __block NSString *showCurrentFileSize = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (currentDataLength>GBUnit)
            showCurrentFileSize = [[NSString alloc] initWithFormat:@"%.1fG", (CGFloat)currentDataLength / (CGFloat)GBUnit];
        if (currentDataLength>MBUnit && currentDataLength<=GBUnit)
            showCurrentFileSize = [[NSString alloc] initWithFormat:@"%.1fMB", (CGFloat)currentDataLength / (CGFloat)MBUnit];
        else if (currentDataLength>KBUnit && currentDataLength<=MBUnit)
            showCurrentFileSize = [[NSString alloc] initWithFormat:@"%lliKB", currentDataLength / KBUnit];
        else if (currentDataLength<=KBUnit)
            showCurrentFileSize = [[NSString alloc] initWithFormat:@"%lliB", currentDataLength];
        dispatch_async(dispatch_get_main_queue(), ^{
            _progressView.progress += value;
            [_lbCurrentFileSize setText:showCurrentFileSize];
        });
    });
    showCurrentFileSize = nil;
}

- (void) startServer
{
    NSError *error;
    if ([_httpserver start:&error])
        [_lbHTTPServer setText:[NSString stringWithFormat:@"Started HTTP Server\nhttp://%@:%hu", [_httpserver hostName], [_httpserver listeningPort]]];
    else
        NSLog(@"Error Started HTTP Server:%@", error);
}

- (void) initViews
{
    _lbHTTPServer = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 50.0, 300.0, 40.0)];
    [_lbHTTPServer setBackgroundColor:[UIColor clearColor]];
    [_lbHTTPServer setFont:[UIFont boldSystemFontOfSize:14.0]];
    [_lbHTTPServer setLineBreakMode:UILineBreakModeWordWrap];
    [_lbHTTPServer setNumberOfLines:2];
    [self.window addSubview:_lbHTTPServer];
    
    _lbFileSize = [[UILabel alloc] initWithFrame:CGRectMake(250.0, 95.0, 60.0, 20.0)];
    [_lbFileSize setBackgroundColor:[UIColor clearColor]];
    [_lbFileSize setFont:[UIFont boldSystemFontOfSize:13.0]];
    [self.window addSubview:_lbFileSize];
    
    _lbCurrentFileSize = [[UILabel alloc] initWithFrame:CGRectMake(188.0, 95.0, 60.0, 20.0)];
    [_lbCurrentFileSize setBackgroundColor:[UIColor clearColor]];
    [_lbCurrentFileSize setFont:[UIFont boldSystemFontOfSize:13.0]];
    [_lbCurrentFileSize setTextAlignment:UITextAlignmentRight];
    [self.window addSubview:_lbCurrentFileSize];
    
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [_progressView setFrame:CGRectMake(10.0, 120.0, 300.0, 20.0)];
    [_progressView setHidden:YES];
    [self.window addSubview:_progressView];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    currentDataLength = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadWithStart:) name:UPLOADSTART object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploading:) name:UPLOADING object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadWithEnd:) name:UPLOADEND object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadWithDisconnect:) name:UPLOADISCONNECTED object:nil];
    
    [self initViews];
    
    _httpserver = [[HTTPServer alloc] init];
    [_httpserver setType:@"_http._tcp."];
    [_httpserver setPort:16918];
    NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"website"];
    [_httpserver setDocumentRoot:webPath];
    [_httpserver setConnectionClass:[AYHTTPConnection class]];
    [self startServer];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [_httpserver stop];
    currentDataLength = 0;
    [_progressView setHidden:YES];
    [_progressView setProgress:0.0];
    [_lbFileSize setText:@""];
    [_lbCurrentFileSize setText:@""];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPLOADSTART object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPLOADING object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPLOADEND object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPLOADISCONNECTED object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self startServer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadWithStart:) name:UPLOADSTART object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploading:) name:UPLOADING object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadWithEnd:) name:UPLOADEND object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadWithDisconnect:) name:UPLOADISCONNECTED object:nil];
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
