//
//  AYHTTPConnection.m
//  InAppWebHTTPServer
//
//  Created by AlimysoYang on 13-8-16.
//  Copyright (c) 2013年 AlimysoYang. All rights reserved.
//

#import "AYHTTPConnection.h"
#import "MultipartFormDataParser.h"
#import "HTTPMessage.h"
#import "MultipartMessageHeader.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPDynamicFileResponse.h"

#import "AYHUploadValueModel.h"

@interface AYHTTPConnection()<MultipartFormDataParserDelegate>

@property (assign, nonatomic) BOOL isUploading;                         //Is not being performed Upload
@property (assign, nonatomic) UInt64 uploadFileSize;                     //The total size of the uploaded file
@property (strong, nonatomic) MultipartFormDataParser *parser;    //
@property (strong, nonatomic) NSFileHandle *storeFile;                  //Storing uploaded files

@property (strong, nonatomic) AYHUploadValueModel *uploadValueModel;

@end

@implementation AYHTTPConnection

#pragma mark HTTP Request and Response
//Connection is disconnected
- (void) die
{
    if (self.isUploading)
    {
        self.isUploading = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:UPLOADISCONNECTED object:nil];
    }
    [super die];
}

- (BOOL) supportsMethod:(NSString *)method atPath:(NSString *)path
{
    //This is very important, if not this code, no response when uploading
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/index.html"])
        return YES;
    return [super supportsMethod:method atPath:path];
}

- (BOOL) expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    //Click on your Web page after uploading executed
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/index.html"])
    {
        NSString *contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if (paramsSeparator==NSNotFound || paramsSeparator>=contentType.length - 1)
            return NO;
        NSString *type = [contentType substringToIndex:paramsSeparator];
        if (![type isEqualToString:@"multipart/form-data"])
            return NO;
        
        NSArray *params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for (NSString *param in params)
        {
            paramsSeparator = [param rangeOfString:@"="].location;
            if (paramsSeparator==NSNotFound || paramsSeparator>=param.length - 1)
                continue;
            
            NSString *paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator - 1)];
            NSString *paramValue = [param substringFromIndex:paramsSeparator + 1];
            if ([paramName isEqualToString:@"boundary"])
                [request setHeaderField:@"boundary" value:paramValue];
        }
        if ([request headerField:@"boundary"]==nil)
            return NO;
        return YES;
    }
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *) httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    //Web pages and upload initialization after the end of the list display uploaded files
    if ([method isEqualToString:@"GET"] || ([method isEqualToString:@"POST"] && [path isEqualToString:@"/index.html"]))
    {
        NSMutableString *fileHtml = [[NSMutableString alloc] initWithString:@""];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] enumeratorAtPath:[paths objectAtIndex:0]];
        NSString *fileName = nil;
        while (fileName=[direnum nextObject])
        {
            [fileHtml appendFormat:@"<a href=\"%@\"> %@ </a><br/>",fileName, [fileName lastPathComponent]];
        }
        
        NSString *templatePath = [[config documentRoot] stringByAppendingPathComponent:@"index.html"];
        NSDictionary *replacementDict = [NSDictionary dictionaryWithObject:fileHtml forKey:@"MyFiles"];
        fileHtml = nil;
        return [[HTTPDynamicFileResponse alloc] initWithFilePath:templatePath forConnection:self separator:@"%" replacementDictionary:replacementDict];
    }
    return [super httpResponseForMethod:method URI:path];
}

#pragma mark private methods
- (void) prepareForBodyWithSize:(UInt64)contentLength
{
    //Get the total length of the uploaded file
    self.uploadFileSize = contentLength;
    //Prepare parsing
    self.parser = [[MultipartFormDataParser alloc] initWithBoundary:[request headerField:@"boundary"] formEncoding:NSUTF8StringEncoding];
    self.parser.delegate = self;
}

- (void) processBodyData:(NSData *)postDataChunk
{
    //Get the current data stream
    [self.parser appendData:postDataChunk];
}

#pragma mark File Transfer Process(Start->Content->End)
- (void) processStartOfPartWithHeader:(MultipartMessageHeader *)header
{
    MultipartMessageHeaderField *disposition = [header.fields objectForKey:@"Content-Disposition"];
    NSString *fileName = [[disposition.params objectForKey:@"filename"] lastPathComponent];
    if (fileName==nil || [fileName isEqualToString:@""])
        return;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *uploadFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    //Ready to write the file, if the file already exists Overwrite
    if (![fm createFileAtPath:uploadFilePath contents:nil attributes:nil])
    {
        return;
    }
    self.isUploading = YES;
    self.storeFile = [NSFileHandle fileHandleForWritingAtPath:uploadFilePath];
    self.uploadValueModel.totalFileSize = self.uploadFileSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:UPLOADSTART object:self.uploadValueModel];
}

- (void) processContent:(NSData *)data WithHeader:(MultipartMessageHeader *)header
{
    if (self.storeFile)
    {
        [self.storeFile writeData:data];
        self.uploadValueModel.dataLength = data.length;
        [[NSNotificationCenter defaultCenter] postNotificationName:UPLOADING object:self.uploadValueModel];
    }
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader *)header
{
    self.isUploading = NO;
    [self.storeFile closeFile];
    self.storeFile = nil;
     [[NSNotificationCenter defaultCenter] postNotificationName:UPLOADEND object:nil];
}

- (void) processPreambleData:(NSData *)data
{
    
}

- (void) processEpilogueData:(NSData *)data
{
    
}

#pragma mark getter & setter
- (AYHUploadValueModel *)uploadValueModel
{
    if (!_uploadValueModel)
    {
        _uploadValueModel = [[AYHUploadValueModel alloc] init];
    }
    return _uploadValueModel;
}
@end
