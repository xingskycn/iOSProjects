//
//  SampleBuffer.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-15.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iOSMediaModulePub.h"

#define MAX_SAMPLE_BUF_LEN 15

@interface SampleBufferAlloctor : NSObject
{
    int currentCnt;
    char *buffer[MAX_SAMPLE_BUF_LEN];
    NSLock *lock;
}

- (id)initWithSize : (int)size;

- (int)getFreeBuf : (char**)buf;

- (int)freeBuf : (char*)buf;

@end

@interface SampleBuffer : NSObject
{
    int currentCnt;
    char *buffer[MAX_SAMPLE_BUF_LEN];
    NSLock *lock;
}

- (int)getBuf : (char**)buf;

- (int)putBuf : (char*)buf;

- (int)getCurrentCount;

@end
