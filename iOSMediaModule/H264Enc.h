//
//  H264Enc.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>

struct x264_t;
struct x264_picture_t;
struct x264_param_t;
struct codecParam;

/**********************************************************
 * 视频数据H264编码类，完成对视频数据的编码工作
 **********************************************************/
class H264Enc
{
private:
    x264_t *x264EncoderHandler;//x264_t
    x264_picture_t *x264EncoderPic;//x264_picture_t
    x264_param_t *x264EncoderParam;//x264_param_t
    
    int width;
    int height;
    int video_bit_rate;
    int fps_num;
    int fps_den;
    
public:
    /**
     * H264编码类构造函数
     * @param param 媒体数据编解码和渲染参数，这里主要用其中的视频编码相关数据
     */
    H264Enc(codecParam *param);
    
    /**
     * H264编码类析构函数
     */
    ~H264Enc();
    
    /**
     * H264编码器初始化
     * @return 成功则返回RC_OK；否则返回值小于0
     */
    int x264_init();
    
    /**
     * H264编码
     * @param i_frame_size 用于返回编码后一帧的长度
     * @param lumaPixel 待编码图像的亮度分量
     * @param chromaPixel 待编码图像的色度分量
     * @return 编码后的nal数据
     */
    uint8_t* x264_encode(int *i_frame_size, unsigned char *lumaPixel, unsigned char *chromaPixel);
    
    /**
     * 将采集到的数据填充到AVPicture中去，即从NV12转换成YUV420
     * @param lumaPixel 采集到的图像的亮度分量
     * @param chromaPixel 采集到的图像的色度分量，两色度分两交替存储的
     */
    void fill_x264_pic(unsigned char *lumaPixel, unsigned char *chromaPixel);
};