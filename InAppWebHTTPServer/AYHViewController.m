//
//  AYHViewController.m
//  InAppWebHTTPServer
//
//  Created by alimysoyang on 15/10/28.
//  Copyright © 2015年 AlimysoYang. All rights reserved.
//

#import "AYHViewController.h"
#import "AYHTTPConnection.h"
#import "HTTPServer.h"

#import "AYHUploadValueModel.h"

//#define GBUnit 1073741824
//#define MBUnit 1048576
//#define KBUnit 1024

#define GBUnit  1000000000
#define MBUnit 1000000
#define KBUnit 1000

@interface AYHViewController ()

@property (strong, nonatomic) HTTPServer *httpserver;
@property (assign, nonatomic) UInt64 currentTotalDataLength;

@property (strong, nonatomic) UIProgressView *progressView;     //upload progress
@property (strong, nonatomic) UILabel *lbHTTPServer;
@property (strong, nonatomic) UILabel *lbFileSize;                      //Total size of uploaded file
@property (strong, nonatomic) UILabel *lbCurrentFileSize;           //The size of the current upload

@end

@implementation AYHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentTotalDataLength = 0;
    [self.view addSubview:self.lbHTTPServer];
    [self.view addSubview:self.progressView];
    [self.view addSubview:self.lbFileSize];
    [self.view addSubview:self.lbCurrentFileSize];
    
    [self startServer];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadWithStart:) name:UPLOADSTART object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploading:) name:UPLOADING object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadWithEnd:) name:UPLOADEND object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadWithDisconnect:) name:UPLOADISCONNECTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark event response
- (void) handleApplicationDidEnterBackground:(NSNotification *)notification
{
    if (self.httpserver)
    {
        [self.httpserver stop];
        [self clearViewsWithStop:YES];
    }
}

- (void) handleApplicationWillEnterForegroundNotification:(NSNotification *)notification
{
    [self startServer];
}

- (void) handleUploadWithStart:(NSNotification *) notification
{
    NSLog(@"文件开始:%@", [self fileSizeFormatter:((AYHUploadValueModel *)notification.object).totalFileSize]);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lbFileSize.text = [NSString stringWithFormat:@"文件大小:%@", [self fileSizeFormatter:((AYHUploadValueModel *)notification.object).totalFileSize]];
    });
}

- (void) handleUploadWithEnd:(NSNotification *) notification
{
    NSLog(@"文件结束");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearViewsWithStop:NO];
    });
}

- (void) handleUploadWithDisconnect:(NSNotification *) notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearViewsWithStop:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Upload data interrupt!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        alert = nil;
    });
}

- (void) handleUploading:(NSNotification *)notification
{
    AYHUploadValueModel *uploadValueModel = (AYHUploadValueModel *)notification.object;
    NSLog(@"文件进度:%f", uploadValueModel.progress);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTotalDataLength += uploadValueModel.dataLength;
        self.progressView.progress += uploadValueModel.progress;
        self.lbCurrentFileSize.text = [NSString stringWithFormat:@"%@", [self fileSizeFormatter:self.currentTotalDataLength]];
    });
}

#pragma mark private methods
- (void) startServer
{
    NSError *error;
    if ([self.httpserver start:&error])
    {
        self.lbHTTPServer.text = [NSString stringWithFormat:@"HTTP Server:%@:%hu", self.httpserver.hostName, self.httpserver.listeningPort];
    }
    else
    {
        self.lbHTTPServer.text = @"Started HTTP Server Error";
        NSLog(@"Error Started HTTP Server:%@", error);
    }
}

- (void) clearViewsWithStop:(BOOL)stop
{
    self.progressView.progress = 0.0;
    self.lbFileSize.text = @"";
    self.lbCurrentFileSize.text = @"";
    if (stop)
    {
        self.lbHTTPServer.text = @"";
    }
}

- (NSString *)fileSizeFormatter:(UInt64)fileSize
{
    if (fileSize>GBUnit)
    {
        return [NSString stringWithFormat:@"%.1fG", (CGFloat)fileSize / (CGFloat)GBUnit];
    }
    if (fileSize>MBUnit && fileSize<=GBUnit)
    {
        return [NSString stringWithFormat:@"%.1fMB", (CGFloat)fileSize / (CGFloat)MBUnit];
    }
    else if (fileSize>KBUnit && fileSize<=MBUnit)
    {
        return [NSString stringWithFormat:@"%lliKB", fileSize / KBUnit];
    }
    else if (fileSize<=KBUnit)
    {
       return [NSString stringWithFormat:@"%lliB", fileSize];
    }
    return @"";
}

#pragma mark getter & setter
- (HTTPServer *)httpserver
{
    if (!_httpserver)
    {
        _httpserver = [[HTTPServer alloc] init];
        [_httpserver setType:@"_http._tcp."];
        [_httpserver setPort:16918];
        NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"website"];
        [_httpserver setDocumentRoot:webPath];
        [_httpserver setConnectionClass:[AYHTTPConnection class]];
    }
    return _httpserver;
}

-(UILabel *)lbHTTPServer
{
    if (!_lbHTTPServer)
    {
        _lbHTTPServer = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 40.0, self.view.frame.size.width - 10.0, 30.0)];
        _lbHTTPServer.font = [UIFont boldSystemFontOfSize:15.0];
        _lbHTTPServer.textColor = [UIColor blackColor];
    }
    return _lbHTTPServer;
}

-(UIProgressView *)progressView
{
    if (!_progressView)
    {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _progressView.frame = CGRectMake(5.0, 72.0, self.view.frame.size.width - 10.0, 20.0);
    }
    return _progressView;
}

-(UILabel *)lbFileSize
{
    if (!_lbFileSize)
    {
        _lbFileSize = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 95.0, 120.0, 20.0)];
        _lbFileSize.font = [UIFont boldSystemFontOfSize:13.0];
        _lbFileSize.textColor = [UIColor blackColor];
    }
    return _lbFileSize;
}

-(UILabel *)lbCurrentFileSize
{
    if (!_lbCurrentFileSize)
    {
        _lbCurrentFileSize = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 125.0, 95.0, 120.0, 20.0)];
        _lbCurrentFileSize.font = [UIFont boldSystemFontOfSize:13.0];
        _lbCurrentFileSize.textColor = [UIColor blackColor];
        _lbCurrentFileSize.textAlignment = NSTextAlignmentRight;
    }
    return _lbCurrentFileSize;
}
@end
