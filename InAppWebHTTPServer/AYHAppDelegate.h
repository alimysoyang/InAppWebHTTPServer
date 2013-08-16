//
//  AYHAppDelegate.h
//  InAppWebHTTPServer
//
//  Created by AlimysoYang on 13-8-16.
//  Copyright (c) 2013年 AlimysoYang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTTPServer;

@interface AYHAppDelegate : UIResponder <UIApplicationDelegate>
{
    UInt64 currentDataLength;
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HTTPServer *httpserver;
@property (strong, nonatomic) UIProgressView *progressView;     //upload progress
@property (strong, nonatomic) UILabel *lbHTTPServer;
@property (strong, nonatomic) UILabel *lbFileSize;                      //Total size of uploaded file
@property (strong, nonatomic) UILabel *lbCurrentFileSize;           //The size of the current upload
@end
