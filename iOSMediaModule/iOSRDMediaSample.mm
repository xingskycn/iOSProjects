//
//  iOSMediaSample.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "iOSRDMediaSample.h"

iOSRDMediaSample::iOSRDMediaSample(int size)
{
    if(size <= 0)
    {
        NSLog(@"数据区长度不能小于0");
        exit(1);
    }
    length = size;
    refCount = 0;
    lock = [[NSLock alloc] init];
    buffer = (char*)malloc(size);
}

iOSRDMediaSample::~iOSRDMediaSample()
{
    if(buffer != NULL)
    {
        free(buffer);
    }
}

int iOSRDMediaSample::GetBuffer(char **buf)
{
    if(buf == NULL)
    {
        return RC_INVALID_ARG;
    }
    *buf = buffer;
    return RC_OK;
}

int iOSRDMediaSample::GetLength()
{
    return length;
}

int iOSRDMediaSample::GetActualLength()
{
    return actualLength;
}

int iOSRDMediaSample::AddRef()
{
    [lock lock];
    refCount++;
    [lock unlock];
    return RC_OK;
}

int iOSRDMediaSample::GetRef()
{
    int ret;
    [lock lock];
    ret = refCount;
    [lock unlock];
    return ret;
}

int iOSRDMediaSample::Release()
{
    if(refCount == 0)
    {
        return RC_UNKNOWN;
    }
    [lock lock];
    refCount--;
    [lock unlock];
    return RC_OK;
}

int iOSRDMediaSample::ReAlloc(int len)
{
    if(len <= 0)
    {
        return RC_INVALID_ARG;
    }
    length = len;
    if(buffer != NULL)
    {
        free(buffer);
    }
    buffer = (char*)malloc(len);
    return RC_OK;
}