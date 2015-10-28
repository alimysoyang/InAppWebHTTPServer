//
//  AYHUploadValueModel.h
//  InAppWebHTTPServer
//
//  Created by alimysoyang on 15/10/28.
//  Copyright © 2015年 AlimysoYang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AYHUploadValueModel : NSObject

@property (assign, nonatomic) UInt64 totalFileSize;          //上传数据的总长度
@property (assign, nonatomic) NSUInteger dataLength;        //当前已上传的数据块长度
@property (assign, nonatomic, readonly) CGFloat progress;                    //当前上传的进度

@end
