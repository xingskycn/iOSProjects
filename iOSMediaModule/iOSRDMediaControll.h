//
//  iOSMediaControll.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iOSMediaModulePub.h"
#import "iOSCam.h"
#import "H264Dec.h"
#import "MediaRender.h"

/**
 * 媒体数据发送线程类，主要是为了使用ios的NSThread，因为它不能
 * 直接在C++类中使用
 */
@interface iOSSendThread : NSObject
{
    IRDReceiverCallBack *callBack;
    MediaBuffer *videoBuffer;
    MediaBuffer *audioBuffer;
    bool b_active;
    NSThread *thread;
}

/**
 * iOSSendThrad类初始化函数
 * @param cb 数据回调接口
 * @param v_buf 视频数据buffer
 * @param a_buf 音频数据buffer
 * @return 返回iOSSendThread类对象
 */
- (id)initWithCallBack : (IRDReceiverCallBack*)cb VideoBuffer : (MediaBuffer*)v_buf AudioBuffer : (MediaBuffer*)a_buf;

/**
 * 开始发送数据
 */
- (void)start;

/**
 * 停止发送数据
 */
- (void)stop;

@end

/**
 * 媒体控制类，继承了媒体控制接口类IRDMediaControl
 */
class iOSRDMediaControll : public IRDMediaControl
{
private:
    codecParam *codecPam;
    IRDReceiverCallBack *callBack;
    IRDReceiverCallBack *retCallBack;
    IRDMemAllocator *retMemAlloc;
    
    //采集加编码
    iOSCam *capture;
    iOSRDMemAllocator *capAlloc;
    MediaBuffer *capVideoBuf;
    MediaBuffer *capAudioBuf;
    
    //解码加渲染
    MediaRender *render;
    iOSRDMemAllocator *renderAloc;
    MediaBuffer *renderVideoBuf;
    MediaBuffer *renderAudioBuf;
    
    iOSSendThread *sendThread;
    
public:
    /**
	 * 初始化媒体控制器
     * @param codecPam 编解码参数
     * @param cb mediastream2实现的媒体回调接口，采集和编码的数据通过此接口发送给发送模块
     * @param sample_cnt sample个数，用于分配器创建
     * @param sample_size sample大小，用于分配器创建
     * @return
     */
    int initialize(codecParam *param, IRDReceiverCallBack *cb, int sample_cnt, int sample_size);
    
    /**
	 * 反初始化媒体控制器
     */
    int release();
    
    /**
	 * 启动媒体控制器
     */
    int start();
    
    /**
	 * 停止媒体控制器
     */
    int stop();
    
    /**
	 * 获取iOSMediaModule的媒体回调接口
     * @return NULL失败，非NULL成功
     */
    IRDReceiverCallBack* getReceiverCallBcak();
    
    /**
	 * 获取iOSMediaModule的媒体存储分配器
     * @return NULL失败，非NULL成功
     */
    IRDMemAllocator* getRDMediaAllocator();
};

