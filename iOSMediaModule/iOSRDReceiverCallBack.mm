//
//  iOSRDReceiverCallBack.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "iOSRDReceiverCallBack.h"
#import "g711common.h"
#import "Common.h"

int iOSRDReceiverCallBack::onPostFrame(char *buf, int buf_len, bool b_key, int64_t startTime, int64_t endTime, iOS_MEDIA_TYPE mediaType)
{
    IRDMediaSample *mediaSample;
    char *buffer;
    MediaHeader header;
    if(mediaType == iOS_MEDIA_TYPE_VIDEO)
    {
        if(mediaDataMemAlloc->GetFreeRDMediaSample(&mediaSample) == RC_OK)
        {
            mediaSample->GetBuffer(&buffer);
            int buf_out_len;
            header.startTime = startTime;
            header.endTime = endTime;
            header.bKey = b_key;
            header.bufLen = buf_len;
            memcpy(buffer, &header, sizeof(MediaHeader));
            [H264Decoder videoDecodeWithInBuf:buf InBufLen:buf_len OutBuf:buffer+MEDIA_HEADER_LEN OutBufLen:&buf_out_len];
            [videoDataBuffer putMediaSample:mediaSample];
        }
    }
    else if(mediaType == iOS_MEDIA_TYPE_AUDIO)
    {
        if(mediaDataMemAlloc->GetFreeRDMediaSample(&mediaSample) == RC_OK)
        {
            mediaSample->GetBuffer(&buffer);
            
            header.startTime = startTime;
            header.endTime = endTime;
            header.bKey = b_key;
            header.bufLen = buf_len*2;
            memcpy(buffer, &header, sizeof(MediaHeader));
            
            SInt16 *sData = (SInt16*)(buffer+MEDIA_HEADER_LEN);
            if(codecPam->audio_codec_id == AUDIO_CODEC_G711_ALAW)
            {
                for(int i=0; i<buf_len; i++)
                {
                    sData[i] = alaw_to_s16(buf[i]);
                }
            }
            else if(codecPam->audio_codec_id == AUDIO_CODEC_G711_ULAW)
            {
                for(int i=0; i<buf_len; i++)
                {
                    sData[i] = ulaw_to_s16(buf[i]);
                }
            }
            else
            {
                NSLog(@"Unknown audio codec");
                return RC_INVALID_ARG;
            }
            [audioDataBuffer putMediaSample:mediaSample];
        }
    }
    else
    {
        NSLog(@"Unknown media type");
        return RC_INVALID_ARG;
    }
    return RC_OK;
}

int iOSRDReceiverCallBack::initialize(iOSRDMemAllocator *alloc, MediaBuffer *v_buf, MediaBuffer *a_buf, codecParam *param)
{
    if(alloc == NULL || v_buf == NULL || a_buf == NULL || param == NULL)
    {
        return RC_INVALID_ARG;
    }
    
    mediaDataMemAlloc = alloc;
    videoDataBuffer = v_buf;
    audioDataBuffer = a_buf;
    codecPam = param;
    
    H264Decoder = [[H264Dec alloc] initWithCodecParam:param];
    return RC_OK;
}

int iOSRDReceiverCallBack::release()
{
    return RC_OK;
}