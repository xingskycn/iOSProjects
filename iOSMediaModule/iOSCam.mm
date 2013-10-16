//
//  iOSCam.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "iOSCam.h"
#import "H264Enc.h"
#import "iOSRDMemAllocator.h"
#import "MediaBuffer.h"
#import "iOSRDMediaSample.h"
#import "g711common.h"
#import <sys/time.h>

#define TestVideo

@implementation iOSCam

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    static int v_frame_cnt = 0;
    static int64_t v_start = 0;
    static int64_t v_pts = 0;
    
    static int a_frame_cnt = 0;
    static int64_t a_start = 0;
    static int64_t a_pts = 0;
    if(b_capture == YES)
    {
        if(connection == videoConnection)
        {
            if(v_frame_cnt%2 == 0)
            {
                CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                
                if(v_frame_cnt == 0)
                {
                    CMTime tmp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    v_start = (double)tmp.value/tmp.timescale*1000000;
                    v_pts = 0;
                }
                else
                {
                    CMTime tmp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    v_pts = ((double)tmp.value/tmp.timescale*1000000 - v_start)/1000;
                }
                
                unsigned char *luma = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
                unsigned char *chroma = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

                int frame_size;
                unsigned char *nalData = H264Encoder->x264_encode(&frame_size, luma, chroma);
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                IRDMediaSample *mediaSample;
                if(mediaDataMemAlloc->GetFreeRDMediaSample(&mediaSample) == RC_OK)
                {
                    char *buf;
                    mediaSample->GetBuffer(&buf);
                    memcpy(buf, &v_pts, sizeof(int64_t));
                    memcpy(buf+sizeof(int64_t), &frame_size, sizeof(int));
                    memcpy(buf+sizeof(int64_t)+sizeof(int), nalData, frame_size);
                    [videoDataBuffer putMediaSample:mediaSample];
                }
                else
                {
                    NSLog(@"No free media sample");
                }
            }
            v_frame_cnt++;
        }
        else if (connection == audioConnection)
        {
            //add
            static double d_index = 0;
            static int64_t totalSamples = 0;
            //add
            
            if(a_frame_cnt == 0)
            {
                CMTime tmp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                a_start = (double)tmp.value/tmp.timescale*1000000;
                a_pts = 0;
            }
            else
            {
                CMTime tmp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                a_pts = ((double)tmp.value/tmp.timescale*1000000 - a_start)/1000;
            }
            
            
            CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(sampleBuffer);
            
            size_t lengthAtOffset;
            size_t totalLength;
            char *data;
            if(CMBlockBufferGetDataPointer(buffer, 0, &lengthAtOffset, &totalLength, &data) != noErr)
            {
                NSLog(@"error");
            }

            IRDMediaSample *mediaSample;
            if(mediaDataMemAlloc->GetFreeRDMediaSample(&mediaSample) == RC_OK)
            {
                int index;
                int numSamples = 0;
                char *buf;
                mediaSample->GetBuffer(&buf);
                memcpy(buf, &a_pts, sizeof(int64_t));
                SInt16 *sData = (SInt16*)data;
                char *compressedData = buf + sizeof(int) + sizeof(int64_t);
                
                if(audio_codec_id == AUDIO_CODEC_G711_ALAW)
                {
                    while((index = (int)((int64_t)(d_index+0.5) - totalSamples)) < totalLength/2)
                    {
                        compressedData[numSamples++] = s16_to_alaw(sData[index]);
                        d_index += 44100.0/8000;
                    }
                }
                else if(audio_codec_id == AUDIO_CODEC_G711_ULAW)
                {
                    while((index = (int)((int64_t)(d_index+0.5) - totalSamples)) < totalLength/2)
                    {
                        compressedData[numSamples++] = s16_to_ulaw(sData[index]);
                        d_index += 44100.0/8000;
                    }
                }
                *((int*)(buf+sizeof(int64_t))) = numSamples;
                totalSamples += totalLength/2;
                //NSLog(@"numSamples = %d", numSamples);
                
//                int numSamples = totalLength/2;
//                char *buf;
//                mediaSample->GetBuffer(&buf);
//                memcpy(buf, &a_pts, sizeof(int64_t));
//                SInt16 *sData = (SInt16*)data;
//                char *compressedData = buf + sizeof(int) + sizeof(int64_t);
//                
//                for(int i=0; i<numSamples; i++)
//                {
//                    if(audio_codec_id == AUDIO_CODEC_G711_ALAW)
//                    {
//                        compressedData[i] = s16_to_alaw(sData[i]);
//                    }
//                    else if(audio_codec_id == AUDIO_CODEC_G711_ULAW)
//                    {
//                        compressedData[i] = s16_to_ulaw(sData[i]);
//                    }
//                }
//                *((int*)(buf+sizeof(int64_t))) = numSamples;
                [audioDataBuffer putMediaSample:mediaSample];
            }
            else
            {
                NSLog(@"No free media sample");
            }
            a_frame_cnt++;
        }
    }
}

//- (void)audioEncodeThreadProc
//{
//    char *audioBuf;
//    while(b_capture)
//    {
//        if([captureAudioBuf getCurrentCount] > 0)
//        {
//            [captureAudioBuf getBuf:&audioBuf];
//            int64_t pts = *((int64_t*)audioBuf);
//            int len = *((int*)(audioBuf+sizeof(int64_t)));
//            SInt16 *sData = (SInt16*)(audioBuf+sizeof(int64_t)+sizeof(int));
//            
//            IRDMediaSample *mediaSample;
//            if(mediaDataMemAlloc->GetFreeRDMediaSample(&mediaSample) == RC_OK)
//            {
//                int numSamples = len/2;
//                char *buf;
//                mediaSample->GetBuffer(&buf);
//                
//                memcpy(buf, &pts, sizeof(int64_t));
//                char *compressedData = buf + sizeof(int) + sizeof(int64_t);
//                
//                for(int i=0; i<numSamples; i++)
//                {
//                    if(audio_codec_id == AUDIO_CODEC_G711_ALAW)
//                    {
//                        compressedData[i] = s16_to_alaw(sData[i]);
//                    }
//                    else if(audio_codec_id == AUDIO_CODEC_G711_ULAW)
//                    {
//                        compressedData[i] = s16_to_ulaw(sData[i]);
//                    }
//                }
//                *((int*)(buf+sizeof(int64_t))) = numSamples;
//                
////                int sampleCnt = 0;
////                for(double i=0; (int)i<numSamples; i += 44100.0/8000)
////                {
////                    if(audio_codec_id == AUDIO_CODEC_G711_ALAW)
////                    {
////                        compressedData[sampleCnt++] = s16_to_alaw(sData[(int)i]);
////                    }
////                    else if(audio_codec_id == AUDIO_CODEC_G711_ULAW)
////                    {
////                        compressedData[sampleCnt++] = s16_to_ulaw(sData[(int)i]);
////                    }
////                }
////                *((int*)(buf+sizeof(int64_t))) = sampleCnt;
//                //NSLog(@"numSamples = %d", sampleCnt);
//                [audioDataBuffer putMediaSample:mediaSample];
//            }
//            [captureAudioBufAloc freeBuf:audioBuf];
//        }
//        else
//        {
//            usleep(1000);
//        }
//    }
//}

//- (void)videoEncodeThreadProc
//{
//    char *YUVBuf;
//    while(b_capture)
//    {
//        if([captureVideoBuf getCurrentCount] > 0)
//        {
//            [captureVideoBuf getBuf:&YUVBuf];
//            int frame_size;
//            int64_t pts = *((int64_t*)YUVBuf);
//            char *luma = YUVBuf + sizeof(int64_t);
//            char *chroma = luma + width*height;
//            unsigned char *nalData = H264Encoder->x264_encode(&frame_size, (unsigned char*)luma, (unsigned char*)chroma);
//            [captureVideoBufAloc freeBuf:YUVBuf];
//            
//            IRDMediaSample *mediaSample;
//            if(mediaDataMemAlloc->GetFreeRDMediaSample(&mediaSample) == RC_OK)
//            {
//                char *buf;
//                mediaSample->GetBuffer(&buf);
//                memcpy(buf, &pts, sizeof(int64_t));
//                memcpy(buf+sizeof(int64_t), &frame_size, sizeof(int));
//                memcpy(buf+sizeof(int64_t)+sizeof(int), nalData, frame_size);
//                [videoDataBuffer putMediaSample:mediaSample];
//            }
//            else
//            {
//                NSLog(@"No free media sample");
//            }
//        }
//        else
//        {
//            usleep(1000);
//        }
//    }
//}

- (int)iOSCam_initWithCodecParam : (codecParam*)param MemAlloc : (iOSRDMemAllocator*)aloc VideoDataBuffer : (MediaBuffer*)v_buf AudioDataBuffer : (MediaBuffer*)a_buf
{
    H264Encoder = new H264Enc(param);
    H264Encoder->x264_init();
    b_capture = NO;
    device_pos = param->capture_device_id;
    pix_fmt = param->pix_fmt;
    width = param->width;
    height = param->height;
    
    mediaDataMemAlloc = aloc;
    videoDataBuffer = v_buf;
    audioDataBuffer = a_buf;
    
    sampleBit = param->sampleBit;
    sampleRate = param->sampleRate;
    audio_bitrate = param->audio_bitrate;
    chanel = param->chanel;
    audio_codec_id = param->audio_codec_id;
    
//    captureVideoBufAloc = [[SampleBufferAlloctor alloc] initWithSize:width*height*3/2+10];
//    captureVideoBuf = [[SampleBuffer alloc] init];
//    videoEncodeThread = [[NSThread alloc] initWithTarget:self selector:@selector(videoEncodeThreadProc) object:nil];
//    
//    captureAudioBufAloc = [[SampleBufferAlloctor alloc] initWithSize:8000*2];
//    captureAudioBuf = [[SampleBuffer alloc] init];
//    audioEncodeThread = [[NSThread alloc] initWithTarget:self selector:@selector(audioEncodeThreadProc) object:nil];
    
    return RC_OK;
}

- (int)start
{
    if(session == nil)
    {
        [self setSession];
    }
    b_capture = YES;
    [session startRunning];
    //[videoEncodeThread start];
    //[audioEncodeThread start];
    return RC_OK;
}

- (int)stop
{
    b_capture = NO;
    [session stopRunning];
    return RC_OK;
}

- (AVCaptureDevice*)cameraWithPosition : (AVCaptureDevicePosition)pos
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for(AVCaptureDevice *device in devices)
    {
        if([device position] == pos)
        {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice*) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice*) backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (int)setSession
{
    session = [[AVCaptureSession alloc] init];
    if(width == 640 && height == 480)
    {
        if([session canSetSessionPreset:AVCaptureSessionPreset640x480])
        {
            [session setSessionPreset:AVCaptureSessionPreset640x480];
        }
        else
        {
            NSLog(@"Unsurported resolution 640x480.");
            return RC_INVALID_ARG;
        }
    }
    else if(width == 352 && height == 288)
    {
        if([session canSetSessionPreset:AVCaptureSessionPreset352x288])
        {
            [session setSessionPreset:AVCaptureSessionPreset352x288];
        }
        else
        {
            NSLog(@"Unsurported resolution 352x288.");
            return RC_INVALID_ARG;
        }
    }
    else
    {
        NSLog(@"Unsurported resolution 352x288.");
        return RC_INVALID_ARG;
    }
    
    AVCaptureDevice *camera;
    if(device_pos == CAPTURE_DEVICE_FRONT)
    {
        camera = [self frontFacingCamera];
    }
    else if (device_pos == CAPTURE_DEVICE_BACK)
    {
        camera = [self backFacingCamera];
    }
    else
    {
        camera = nil;
    }
    
    if(camera == nil)
    {
        NSLog(@"No device found.");
        return RC_INVALID_ARG;
    }
    NSError *err;
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&err];
    if(err)
    {
        NSLog(@"AVCaptureDeviceInput: initWithDevice failed.");
        return RC_UNKNOWN;
    }
    
    if([session canAddInput:videoIn])
    {
        [session addInput:videoIn];
    }
    else
    {
        NSLog(@"Could not add input videoIn.");
        return RC_UNKNOWN;
    }
    
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
        [videoOut setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    dispatch_queue_t videoCaptureQueue = dispatch_queue_create("video capture queue", DISPATCH_QUEUE_SERIAL);
    [videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    if([session canAddOutput:videoOut])
    {
        [session addOutput:videoOut];
    }
    else
    {
        NSLog(@"Could not add output videoOut");
        return RC_UNKNOWN;
    }
    
    videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevice *audioDevice = nil;
    AVCaptureDeviceInput *audioIn;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if([devices count] > 0)
    {
        audioDevice = [devices objectAtIndex:0];
    }
    else
    {
        NSLog(@"No audio device");
        return RC_UNKNOWN;
    }
    if(audioDevice != nil)
    {
        audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
    }
    else
    {
        NSLog(@"audioDevice is nil");
        return RC_UNKNOWN;
    }
    
    if([session canAddInput:audioIn])
    {
        [session addInput:audioIn];
    }
    else
    {
        NSLog(@"Could not add input audioIn");
        return RC_UNKNOWN;
    }
    
    AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
    dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    [audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];
    
    if([session canAddOutput:audioOut])
    {
        [session addOutput:audioOut];
    }
    else
    {
        NSLog(@"Could not add output audioOut");
        return RC_UNKNOWN;
    }
    audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
    
    return RC_OK;
}

@end
