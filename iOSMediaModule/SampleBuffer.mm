//
//  SampleBuffer.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-15.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "SampleBuffer.h"

@implementation SampleBufferAlloctor

- (id)initWithSize:(int)size
{
    if(size <= 0)
    {
        NSLog(@"Buffer大小必须大于0");
        exit(1);
    }
    self = [super init];
    if(self)
    {
        currentCnt = MAX_SAMPLE_BUF_LEN;
        lock = [[NSLock alloc] init];
        int i;
        for(i=0; i<MAX_SAMPLE_BUF_LEN; i++)
        {
            buffer[i] = (char*)malloc(size);
            if(buffer[i] == NULL)
            {
                NSLog(@"Allocate buffer[%d] failed", i);
                exit(1);
            }
        }
    }
    return self;
}

- (int)getFreeBuf:(char **)buf
{
    if(buf == NULL)
    {
        return RC_INVALID_ARG;
    }
    [lock lock];
    if(currentCnt == 0)
    {
        [lock unlock];
        return RC_OUT_MEM;
    }
    *buf = buffer[--currentCnt];
    [lock unlock];
    return RC_OK;
}

- (int)freeBuf:(char *)buf
{
    [lock lock];
    if(buf == NULL || currentCnt == MAX_SAMPLE_BUF_LEN)
    {
        [lock unlock];
        return RC_INVALID_ARG;
    }
    buffer[currentCnt++] = buf;
    [lock unlock];
    return RC_OK;
}

@end

@implementation SampleBuffer

- (id)init
{
    self = [super init];
    if (self)
    {
        currentCnt = 0;
        lock = [[NSLock alloc] init];
        int i;
        for(i=0; i<MAX_SAMPLE_BUF_LEN; i++)
        {
            buffer[i] = NULL;
        }
    }
    return self;
}

- (int)getBuf:(char **)buf
{
    if(buf == NULL)
    {
        return RC_INVALID_ARG;
    }
    [lock lock];
    if(currentCnt == 0)
    {
        [lock unlock];
        return RC_OUT_MEM;
    }
    *buf = buffer[0];
    currentCnt--;
    int i;
    for(i=0; i<currentCnt; i++)
    {
        buffer[i] = buffer[i+1];
    }
    buffer[i] = NULL;
    [lock unlock];
    return RC_OK;
}

- (int)putBuf:(char *)buf
{
    [lock lock];
    if(buf == NULL || currentCnt == MAX_SAMPLE_BUF_LEN)
    {
        [lock unlock];
        return RC_INVALID_ARG;
    }
    buffer[currentCnt++] = buf;
    [lock unlock];
    return RC_OK;
}

- (int)getCurrentCount
{
    int ret;
    [lock lock];
    ret = currentCnt;
    [lock unlock];
    return ret;
}

@end
