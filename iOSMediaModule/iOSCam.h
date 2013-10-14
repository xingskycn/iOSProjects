//
//  iOSCam.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "iOSMediaModulePub.h"

class H264Enc;
class iOSRDMemAllocator;
@class MediaBuffer;

/**********************************************************
 * 媒体数据采集类，完成数据采集加编码
 **********************************************************/
@interface iOSCam : NSObject<AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    BOOL b_capture;
    AVCaptureSession *session;
    iOS_CAPTURE_DEVICE device_pos;
    iOS_PIXEL_FORMAT pix_fmt;
    int width;
    int height;
    
    int sampleRate;
	int sampleBit;
	int chanel;
	int audio_bitrate;
	AUDIO_CODEC audio_codec_id;
    
    H264Enc *H264Encoder;
    iOSRDMemAllocator *mediaDataMemAlloc;
    MediaBuffer *videoDataBuffer;
    MediaBuffer *audioDataBuffer;
    
    AVCaptureConnection *videoConnection;
    AVCaptureConnection *audioConnection;
}

/**
 * 媒体数据采集类初始化函数
 * @param param 媒体数据编解码和渲染参数，这里主要用到编码相关参数
 * @param aloc 媒体数据内存分配器
 * @param v_buf 视频数据buffer
 * @param a_buf 音频数据buffer
 * @return 成功则返回RC_OK；否则返回值小于0
 */
- (int)iOSCam_initWithCodecParam : (codecParam*)param MemAlloc : (iOSRDMemAllocator*)aloc VideoDataBuffer : (MediaBuffer*)v_buf AudioDataBuffer : (MediaBuffer*)a_buf;

/**
 * 开始数据采集
 */
- (int)start;

/**
 * 停止数据采集
 */
- (int)stop;

@end
