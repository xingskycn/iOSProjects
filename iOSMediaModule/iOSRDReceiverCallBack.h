//
//  iOSRDReceiverCallBack.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iOSMediaModulePub.h"
#import "iOSRDMemAllocator.h"
#import "MediaBuffer.h"
#import "H264Dec.h"

/**********************************************************
 * 媒体数据回调类，继承媒体数据回调接口类
 **********************************************************/
class iOSRDReceiverCallBack : public IRDReceiverCallBack
{
private:
    iOSRDMemAllocator *mediaDataMemAlloc;
    MediaBuffer *videoDataBuffer;
    MediaBuffer *audioDataBuffer;
    H264Dec *H264Decoder;
    codecParam *codecPam;
    
public:
    /**
	 * 投递媒体数据
     * @param buf 媒体数据指针
     * @param buf_len 媒体数据长度
     * @param b_key 视频数据是否是关键帧，音频数据忽略
     * @param startTime,endTime媒体数据的起始和结束时间，单位ms
     * @param mediaType媒体数据类型
     * @return
     */
    int onPostFrame(char *buf, int buf_len, bool b_key, int64_t startTime, int64_t endTime, iOS_MEDIA_TYPE mediaType);
    
    /**
     * 媒体数据回调类初始化函数
     * @param alloc 媒体数据内存分配器
     * @param v_buf 视频数据buffer
     * @param a_buf 音频数据buffer
     * @param param 媒体数据编解码和渲染参数
     * @return 成功则返回RC_OK；否则返回值小于0
     */
    int initialize(iOSRDMemAllocator *alloc, MediaBuffer *v_buf, MediaBuffer *a_buf, codecParam *param);
    
    /**
     * 媒体数据回调类反初始化函数
     * @return
     */
    int release();
};