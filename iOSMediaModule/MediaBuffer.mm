//
//  VideoBuffer.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-9.
//  Copyright (c) 2013年 liyang. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "MediaBuffer.h"



@implementation MediaBuffer

- (id)initWithMaxCount:(int)maxCnt
{
    self = [super init];
    if(self)
    {
        maxCount = maxCnt;
        currentCount = 0;
        lock = [[NSLock alloc] init];
        mediaSample = new IRDMediaSample*[maxCount];
        for(int i=0; i<maxCount; i++)
        {
            mediaSample[i] = NULL;
        }
    }
    return self;
}

- (int)getMediaSample:(IRDMediaSample **)sample
{
    if(sample == NULL)
    {
        return RC_INVALID_ARG;
    }
    [lock lock];
    if(currentCount == 0)
    {
        [lock unlock];
        return RC_OUT_MEM;
    }
    *sample = mediaSample[0];
    currentCount--;
    int i;
    for(i=0; i<currentCount; i++)
    {
        mediaSample[i] = mediaSample[i+1];
    }
    mediaSample[i] = NULL;
    [lock unlock];
    return RC_OK;
}

- (int)putMediaSample:(IRDMediaSample *)sample
{
    if(sample == NULL)
    {
        return RC_INVALID_ARG;
    }
    [lock lock];
    if(currentCount == maxCount)
    {
        [lock unlock];
        return RC_UNKNOWN;
    }
    mediaSample[currentCount++] = sample;
    [lock unlock];
    return RC_OK;
}

- (int)getCurrentCount:(int *)cnt
{
    if(cnt == NULL)
    {
        return RC_INVALID_ARG;
    }
    [lock lock];
    *cnt = currentCount;
    [lock unlock];
    return RC_OK;
}

- (int)getCurrentCount
{
    int ret;
    [lock lock];
    ret = currentCount;
    [lock unlock];
    return ret;
}

@end
