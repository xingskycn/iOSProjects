//
//  H264Enc.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "H264Enc.h"
#import "iOSMediaModulePub.h"
#import <arm_neon.h>
extern "C"
{
#import "x264.h"
}


H264Enc::H264Enc(codecParam *param)
{
    width = param->width;
    height = param->height;
    video_bit_rate = param->video_bitrate;
    fps_den = param->fps_den;
    fps_num = param->fps_num;
}

int H264Enc::x264_init()
{
    x264EncoderParam = (x264_param_t*)malloc(sizeof(x264_param_t));
    if(x264EncoderParam == NULL)
    {
        NSLog(@"Allocate x264_param_t failed.");
        return RC_OUT_MEM;
    }
    
    x264_param_default(x264EncoderParam);
    x264_param_default_preset(x264EncoderParam, "ultrafast", "zerolatency");
    x264EncoderParam->i_threads = 1;
    x264EncoderParam->i_width = width;
    x264EncoderParam->i_height = height;
    x264EncoderParam->rc.i_bitrate = video_bit_rate;
    x264EncoderParam->rc.i_rc_method = X264_RC_ABR;
    x264EncoderParam->i_log_level = X264_LOG_NONE;
    x264EncoderParam->analyse.b_psnr = 1;
    x264EncoderParam->analyse.b_psy = 0;
    x264EncoderParam->i_keyint_max = 25;
    
    if((x264EncoderHandler = x264_encoder_open_135(x264EncoderParam)) == NULL)
    {
        NSLog(@"x264_encoder_open failed.");
        return RC_ENCODE_ERROR;
    }
    
    x264EncoderPic = (x264_picture_t*)malloc(sizeof(x264_picture_t));
    if(x264EncoderPic == NULL)
    {
        NSLog(@"Allocate x264_picture_t failed.");
        return RC_OUT_MEM;
    }
    
    memset(x264EncoderPic, 0, sizeof(x264_picture_t));
    if((x264_picture_alloc(x264EncoderPic, X264_CSP_I420, width, height)) != 0)
    {
        NSLog(@"x264_picture_alloc failed.");
        return RC_OUT_MEM;
    }
    
    x264EncoderPic->i_type = X264_TYPE_AUTO;
    
    return RC_OK;
}

void H264Enc::fill_x264_pic(unsigned char *lumaPixel, unsigned char *chromaPixel)
{
    int x, y;
    unsigned char *pix1 = lumaPixel;
    unsigned char *pix2 = chromaPixel;
    //luma plane
    for(y=0; y<height; y++)
    {
        memcpy(x264EncoderPic->img.plane[0]+y*x264EncoderPic->img.i_stride[0], pix1, width);
        pix1 += width;
    }
    
    //chroma plane
    for(y=0; y<height/2; y++)
    {
        for(x=0; x<width/16; x++)
        {
            uint8x8x2_t tmppix = vld2_u8(pix2);
            vst1_u8(x264EncoderPic->img.plane[1]+y*x264EncoderPic->img.i_stride[1]+x*8, tmppix.val[0]);
            vst1_u8(x264EncoderPic->img.plane[2]+y*x264EncoderPic->img.i_stride[2]+x*8, tmppix.val[1]);
            pix2 += 16;
        }
    }
}

uint8_t* H264Enc::x264_encode(int *i_frame_size, unsigned char *lumaPixel, unsigned char *chromaPixel)
{
    int i_nal;
    x264_nal_t *nal;
    fill_x264_pic(lumaPixel, chromaPixel);
    x264_picture_t pic_out;
    *i_frame_size = x264_encoder_encode(x264EncoderHandler, &nal, &i_nal, x264EncoderPic, &pic_out);
    return nal->p_payload;
}