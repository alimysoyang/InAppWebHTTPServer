//
//  AYHUploadValueModel.m
//  InAppWebHTTPServer
//
//  Created by alimysoyang on 15/10/28.
//  Copyright © 2015年 AlimysoYang. All rights reserved.
//

#import "AYHUploadValueModel.h"

@implementation AYHUploadValueModel

- (void)setDataLength:(NSUInteger)dataLength
{
    _dataLength = dataLength;
    if (self.totalFileSize == 0)
    {
        _progress = 0;
    }
    else
    {
        _progress = (CGFloat)dataLength / (CGFloat)self.totalFileSize;
    }
}
@end
