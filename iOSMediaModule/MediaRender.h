//
//  MediaRender.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-11.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "iOSMediaModulePub.h"
#import "iOSRDMediaSample.h"
#import "iOSRDMemAllocator.h"
#import "MediaBuffer.h"
#import <AudioToolbox/AudioToolbox.h>

/**********************************************************
 * 媒体数据渲染类，显示视频画面，播放音频，实现音视频同步
 **********************************************************/
@interface MediaRender : NSObject<GLKViewDelegate>
{
    //video render param
    GLKView *displayView;
    EAGLContext *context;
    int top;
    int left;
    int bottom;
    int right;
    int width;
    int height;
    int fps_num;
    int fps_den;
    GLuint textureY, textureU, textureV;
    GLuint v, f, p;
    
    //media buffer
    MediaBuffer *videoDataBuffer;
    MediaBuffer *audioDataBuffer;
    
    //audio render param
    AudioStreamBasicDescription dataFormat;
    AudioQueueRef queue;
    AudioQueueBufferRef buffers[3];

    BOOL b_active;
}

/**
 * 媒体数据渲染类初始化函数
 * @param param 媒体数据编解码和渲染参数，这里主要用了其中的渲染参数
 * @param v_buf 视频数据buffer
 * @param a_buf 音频数据buffer
 * @return 成功则返回RC_OK；否则返回值小于0
 */
- (int)initWithCodecParam : (codecParam*)param VideoDataBuffer : (MediaBuffer*)v_buf AudioDataBuffer : (MediaBuffer*)a_buf;

/**
 * 开始媒体数据渲染
 */
- (int)start;

/**
 * 停止媒体数据渲染
 */
- (int)stop;

@end