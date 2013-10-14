//
//  H264Dec.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-11.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
extern "C"
{
#import "libavcodec/avcodec.h"
}
#import "iOSMediaModulePub.h"

/**********************************************************
 * 视频数据H264解码类，完成对视频数据的解码工作
 **********************************************************/
@interface H264Dec : NSObject
{
    AVFrame *frame;
    AVPacket packet;
    AVCodec *codec;
    AVCodecContext *codecContext;
    int video_codec_id;
    int fps_num;
    int fps_den;
}

/**
 * 视频数据解码类初始化函数
 * @param param 媒体数据编解码加渲染参数，这里主要用到其中的解码参数
 * @return 视频数据解码类对象
 */
- (id)initWithCodecParam : (codecParam*)param;

/**
 * 视频数据解码函数
 * @param buf_in 待解码的视频数据区指针
 * @param buf_in_len 待解码的视频数据长度
 * @param buf_out 解码后的视频数据区指针
 * @param buf_out_len 返回解码后视频数据长度
 * @return 成功则返回RC_OK；失败则返回值小于0
 */
- (int)videoDecodeWithInBuf : (char*)buf_in InBufLen : (int)buf_in_len OutBuf : (char*)buf_out OutBufLen : (int*)buf_out_len;

@end