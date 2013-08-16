//
//  AYHTTPConnection.h
//  InAppWebHTTPServer
//
//  Created by AlimysoYang on 13-8-16.
//  Copyright (c) 2013年 AlimysoYang. All rights reserved.
//

#import "HTTPConnection.h"
#import "MultipartFormDataParser.h"

@interface AYHTTPConnection : HTTPConnection<MultipartFormDataParserDelegate>
{
    BOOL isUploading;                         //Is not being performed Upload
    MultipartFormDataParser *parser;    //
    NSFileHandle *storeFile;                  //Storing uploaded files
    UInt64 uploadFileSize;                     //The total size of the uploaded file
}

@end
