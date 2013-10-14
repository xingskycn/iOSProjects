//
//  H264Dec.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-11.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "H264Dec.h"

@implementation H264Dec

- (id)initWithCodecParam:(codecParam *)param
{
    self = [super init];
    if(self)
    {
        fps_den = param->fps_den;
        fps_num = param->fps_num;
        if(param->video_codec_id != VIDEO_CODEC_H264)
        {
            NSLog(@"Only surport H264 decode.");
            exit(1);
        }
        video_codec_id = param->video_codec_id == VIDEO_CODEC_H264 ? AV_CODEC_ID_H264 : AV_CODEC_ID_NONE;
        
        //注册并查找AVCodec
        avcodec_register_all();
        codec = avcodec_find_decoder((enum AVCodecID)video_codec_id);
        if(codec == NULL)
        {
            NSLog(@"Video codec not found");
            exit(1);
        }
        
        //Allocate AVCodecContext
        codecContext = avcodec_alloc_context3(codec);
        if(codecContext == NULL)
        {
            NSLog(@"Could not allocate AVCodecContext");
            exit(1);
        }
        
        if(codec->capabilities & CODEC_CAP_TRUNCATED)
        {
            codecContext->flags |= CODEC_CAP_TRUNCATED;
        }
        
        //Open codec
        if(avcodec_open2(codecContext, codec, NULL) < 0)
        {
            NSLog(@"Could not open codec");
            exit(1);
        }
        
        //初始化AVPacket
        av_init_packet(&packet);
        
        //Allocate AVFrame
        frame = avcodec_alloc_frame();
        if(frame == NULL)
        {
            NSLog(@"Allocate AVFrame failed");
            exit(1);
        }
    }
    return self;
}

- (int)videoDecodeWithInBuf:(char *)buf_in InBufLen:(int)buf_in_len OutBuf:(char *)buf_out OutBufLen:(int*)buf_out_len
{
    if(buf_in == NULL || buf_in_len == 0 || buf_out == NULL || buf_out_len == NULL)
    {
        return RC_INVALID_ARG;
    }
    packet.size = buf_in_len;
    packet.data = (uint8_t*)buf_in;
    int got_frame;
    if(avcodec_decode_video2(codecContext, frame, &got_frame, &packet) < 0)
    {
        NSLog(@"Error while decoding a frame.");
        return RC_VIDEO_DECODE_ERROR;
    }
    if(got_frame == 0)
    {
        return RC_VIDEO_DECODE_ERROR;
    }
    int width = codecContext->width;
    int height = codecContext->height;
    char *Y = buf_out;
    char *U = Y + width*height;
    char *V = U + width*height/4;
    
    for(int y=0; y<height; y++)
    {
        memcpy(Y+y*width, frame->data[0]+y*frame->linesize[0], width);
    }
    //chroma plane
    for(int y=0; y<height/2; y++)
    {
        memcpy(U+y*width/2, frame->data[1]+y*frame->linesize[1], width/2);
        memcpy(V+y*width/2, frame->data[2]+y*frame->linesize[2], width/2);
    }
    
    *buf_out_len = width*height*3/2;
    
    return RC_OK;
}

@end