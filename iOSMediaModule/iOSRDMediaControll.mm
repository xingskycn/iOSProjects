//
//  iOSMediaControll.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "iOSRDMediaControll.h"
#import "iOSRDReceiverCallBack.h"
#import "iOSRDMemAllocator.h"
#import "Common.h"

@implementation iOSSendThread
//媒体数据发送线程函数
- (void)threadProc
{
    int cntv;
    int cnta;
    IRDMediaSample *mediaSample;
    char *buf;
    int buf_len;
    int64_t startTime;
    
    while(b_active)
    {
        [videoBuffer getCurrentCount:&cntv];
        if(cntv > 0)
        {
            [videoBuffer getMediaSample:&mediaSample];
            mediaSample->GetBuffer(&buf);
            startTime = *((int64_t*)buf);
            buf_len = *((int*)(buf+sizeof(int64_t)));
            callBack->onPostFrame(buf+sizeof(int64_t)+sizeof(int), buf_len, false, startTime, 0, iOS_MEDIA_TYPE_VIDEO);
            mediaSample->Release();
        }
        [audioBuffer getCurrentCount:&cnta];
        if(cnta > 0)
        {
            [audioBuffer getMediaSample:&mediaSample];
            mediaSample->GetBuffer(&buf);
            startTime = *((int64_t*)buf);
            buf_len = *((int*)(buf+sizeof(int64_t)));
            callBack->onPostFrame(buf+sizeof(int64_t)+sizeof(int), buf_len, false, startTime, 0, iOS_MEDIA_TYPE_AUDIO);
            mediaSample->Release();
        }
        if(cnta <= 0 && cntv <= 0)
        {
            usleep(1000);
        }
    }
}

- (void)start
{
    b_active = YES;
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadProc) object:nil];
    [thread start];
}

- (void)stop
{
    b_active = NO;
}

- (id)initWithCallBack:(IRDReceiverCallBack *)cb VideoBuffer:(MediaBuffer *)v_buf AudioBuffer:(MediaBuffer *)a_buf
{
    self = [super init];
    if(self)
    {
        callBack = cb;
        videoBuffer = v_buf;
        audioBuffer = a_buf;
        b_active = NO;
    }
    return self;
}

@end


int iOSRDMediaControll::initialize(codecParam *param, IRDReceiverCallBack *cb, int sample_cnt, int sample_size)
{
    if(param == NULL || cb == NULL)
    {
        return RC_INVALID_ARG;
    }
    
    codecPam = param;
    
    //m
    callBack = cb;
    
    capAlloc = new iOSRDMemAllocator();
    capAlloc->SetProperty(50, param->width*param->height*3/2);
    capAlloc->Commit();
    
    capVideoBuf = [[MediaBuffer alloc] initWithMaxCount:50];
    capAudioBuf = [[MediaBuffer alloc] initWithMaxCount:50];
    
    capture = [[iOSCam alloc] init];
    [capture iOSCam_initWithCodecParam:param MemAlloc:capAlloc VideoDataBuffer:capVideoBuf AudioDataBuffer:capAudioBuf];
    
    sendThread = [[iOSSendThread alloc] initWithCallBack:cb VideoBuffer:capVideoBuf AudioBuffer:capAudioBuf];
    
    
    renderAloc = new iOSRDMemAllocator();
    renderAloc->SetProperty(50, param->width*param->height*3/2+MEDIA_HEADER_LEN);
    renderAloc->Commit();
    
    renderVideoBuf = [[MediaBuffer alloc] initWithMaxCount:50];
    renderAudioBuf = [[MediaBuffer alloc] initWithMaxCount:50];
    
    render = [[MediaRender alloc] init];
    int ret;
    ret = [render initWithCodecParam:param VideoDataBuffer:renderVideoBuf AudioDataBuffer:renderAudioBuf];
    if(ret != RC_OK)
    {
        return ret;
    }
    
    retCallBack = new iOSRDReceiverCallBack();
    ((iOSRDReceiverCallBack*)retCallBack)->initialize(renderAloc, renderVideoBuf, renderAudioBuf, param);
    
    if(sample_size <= 0 || sample_cnt <= 0)
    {
        return RC_INVALID_ARG;
    }
    retMemAlloc = new iOSRDMemAllocator();
    retMemAlloc->SetProperty(sample_cnt, sample_size);
    retMemAlloc->Commit();
    //m
    
    
    
    
//    if(param->b_enc == true)
//    {
//        if(cb == NULL)
//        {
//            return RC_INVALID_ARG;
//        }
//        
//        callBack = cb;
//        
//        capAlloc = new iOSRDMemAllocator();
//        capAlloc->SetProperty(50, param->width*param->height*3/2);
//        capAlloc->Commit();
//        
//        capVideoBuf = [[MediaBuffer alloc] initWithMaxCount:50];
//        capAudioBuf = [[MediaBuffer alloc] initWithMaxCount:50];
//        
//        capture = [[iOSCam alloc] init];
//        [capture iOSCam_initWithCodecParam:param MemAlloc:capAlloc VideoDataBuffer:capVideoBuf AudioDataBuffer:capAudioBuf];
//        
//        render = nil;
//        renderAloc = NULL;
//        renderAudioBuf = nil;
//        renderVideoBuf = nil;
//        
//        retCallBack = NULL;
//        
//        sendThread = [[iOSSendThread alloc] initWithCallBack:cb VideoBuffer:capVideoBuf AudioBuffer:capAudioBuf];
//    }
//    else
//    {        
//        renderAloc = new iOSRDMemAllocator();
//        renderAloc->SetProperty(50, param->width*param->height*3/2+MEDIA_HEADER_LEN);
//        renderAloc->Commit();
//        
//        renderVideoBuf = [[MediaBuffer alloc] initWithMaxCount:50];
//        renderAudioBuf = [[MediaBuffer alloc] initWithMaxCount:50];
//        
//        render = [[MediaRender alloc] init];
//        int ret;
//        ret = [render initWithCodecParam:param VideoDataBuffer:renderVideoBuf AudioDataBuffer:renderAudioBuf];
//        if(ret != RC_OK)
//        {
//            return ret;
//        }
//        
//        retCallBack = new iOSRDReceiverCallBack();
//        ((iOSRDReceiverCallBack*)retCallBack)->initialize(renderAloc, renderVideoBuf, renderAudioBuf, param);
//    }
//    
//    if(sample_size <= 0 || sample_cnt <= 0)
//    {
//        return RC_INVALID_ARG;
//    }
//    retMemAlloc = new iOSRDMemAllocator();
//    retMemAlloc->SetProperty(sample_cnt, sample_size);
//    retMemAlloc->Commit();
    
    return RC_OK;
}

int iOSRDMediaControll::release()
{
    if(retCallBack != NULL)
    {
        delete (iOSRDReceiverCallBack*)retCallBack;
    }    
    retMemAlloc->DeCommit();
    delete (iOSRDMemAllocator*)retMemAlloc;
    return RC_OK;
}

int iOSRDMediaControll::start()
{
    [sendThread start];
    [capture start];
    [render start];
    
//    if(codecPam->b_enc == true)
//    {
//        [sendThread start];
//        [capture start];
//    }
//    else
//    {
//        [render start];
//    }
    return RC_OK;
}

int iOSRDMediaControll::stop()
{
    [capture stop];
    [sendThread stop];
    [render stop];
    
//    if(codecPam->b_enc == true)
//    {
//        [capture stop];
//        [sendThread stop];
//    }
//    else
//    {
//        [render stop];
//    }
    return RC_OK;
}

IRDReceiverCallBack* iOSRDMediaControll::getReceiverCallBcak()
{
    return retCallBack;
}

IRDMemAllocator* iOSRDMediaControll::getRDMediaAllocator()
{
    return retMemAlloc;
}

IRDMediaControl* create_iOSRDMediaModule()
{
    return new iOSRDMediaControll();
}

int destroy_iOSRDMediaModule(IRDMediaControl* mediaControl)
{
    if(mediaControl != NULL)
        delete (iOSRDMediaControll*)mediaControl;
    return RC_OK;
}