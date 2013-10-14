//
//  iOSRDMemAllocator.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "iOSRDMemAllocator.h"
#import "iOSRDMediaSample.h"


iOSRDMemAllocator::iOSRDMemAllocator()
{
    lock = [[NSLock alloc] init];
    sampleCount = 0;
    sampleSize = 0;
}

int iOSRDMemAllocator::GetFreeRDMediaSample(IRDMediaSample **psample)
{
    if(psample == NULL)
    {
        return RC_INVALID_ARG;
    }
    [lock lock];
    int i;
    for(i=0; i<sampleCount; i++)
    {
        if(mediaSample[i]->GetRef() == 0)
        {
            *psample = (IRDMediaSample*)mediaSample[i];
            mediaSample[i]->AddRef();
            break;
        }
    }
    if(i == sampleCount)
    {
        *psample = NULL;
        [lock unlock];
        return RC_OUT_MEM;
    }
    [lock unlock];
    return RC_OK;
}

int iOSRDMemAllocator::ReallocRDMediaSample(IRDMediaSample **psample, int size)
{
    if(psample == NULL || *psample == NULL || size <= 0)
    {
        return RC_INVALID_ARG;
    }
    ((iOSRDMediaSample*)(*psample))->ReAlloc(size);
    return RC_OK;
}

int iOSRDMemAllocator::GetProperty(int *sample_cnt, int *sample_size)
{
    if(sample_cnt == NULL || sample_size == NULL)
    {
        return RC_INVALID_ARG;
    }
    *sample_cnt = sampleCount;
    *sample_size = sampleSize;
    return RC_OK;
}

int iOSRDMemAllocator::SetProperty(int sample_cnt, int sample_size)
{
    if(sample_cnt <= 0 || sample_size <= 0)
    {
        return RC_INVALID_ARG;
    }
    sampleCount = sample_cnt;
    sampleSize = sample_size;
    return RC_OK;
}

int iOSRDMemAllocator::Commit()
{
    mediaSample = new iOSRDMediaSample*[sampleCount];
    if(mediaSample == NULL)
    {
        return RC_OUT_MEM;
    }
    int i;
    for(i=0; i<sampleCount; i++)
    {
        mediaSample[i] = new iOSRDMediaSample(sampleSize);
        if(mediaSample[i] == NULL)
        {
            return RC_OUT_MEM;
        }
    }
    return RC_OK;
}

int iOSRDMemAllocator::DeCommit()
{
    delete [] mediaSample;
    delete mediaSample;
    return RC_OK;
}