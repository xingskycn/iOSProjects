//
//  MediaRender.m
//  iOSMediaModule
//
//  Created by liyang on 13-10-11.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import "MediaRender.h"
#import "Common.h"
#import <sys/time.h>

#define ATTRIB_VERTEX 3
#define ATTRIB_TEXTURE 4

@implementation MediaRender

static void bufferCallBack(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef buffer)
{
    [((__bridge MediaRender*)inUserData) audioQueueOutputWithQueue:inAQ queueBuffer:buffer];
}

- (void)audioQueueOutputWithQueue: (AudioQueueRef)audioQueue queueBuffer:(AudioQueueBufferRef)audioQueueBuffer
{
    IRDMediaSample *mediaSample;
    char *buf;
    MediaHeader header;
    if([audioDataBuffer getMediaSample:&mediaSample] == RC_OK)
    {
        mediaSample->GetBuffer(&buf);
        memcpy(&header, buf, sizeof(MediaHeader));
        
        AudioQueueBufferRef outBuffer = audioQueueBuffer;
        memcpy(outBuffer->mAudioData, buf+MEDIA_HEADER_LEN, header.bufLen);
        outBuffer->mAudioDataByteSize = header.bufLen;
        AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer, 0, nil);
        mediaSample->Release();
    }
    else
    {
        //NSLog(@"No data");
        audioQueueBuffer->mAudioDataByteSize = 1;
        memset(audioQueueBuffer->mAudioData, 0, 1);
        AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer, 0, nil);
    }
}

- (int)fillAudioQueueBuffer : (AudioQueueBufferRef)audioQueueBuffer
{
    IRDMediaSample *mediaSample;
    char *buf;
    MediaHeader header;
    if([audioDataBuffer getMediaSample:&mediaSample] == RC_OK)
    {
        mediaSample->GetBuffer(&buf);
        memcpy(&header, buf, sizeof(MediaHeader));
        
        AudioQueueBufferRef outBuffer = audioQueueBuffer;
        memcpy(outBuffer->mAudioData, buf+MEDIA_HEADER_LEN, header.bufLen);
        outBuffer->mAudioDataByteSize = header.bufLen;
        AudioQueueEnqueueBuffer(queue, audioQueueBuffer, 0, nil);
        mediaSample->Release();
        return RC_OK;
    }
    return RC_UNKNOWN;
}

const GLbyte vShaderStr[] =
"attribute vec4 vPosition;    \n"
"attribute vec4 a_texCoord;	\n"
"varying vec2 tc;		\n"
"void main()                  \n"
"{                            \n"
"   gl_Position = vPosition;  \n"
"	  tc = a_texCoord.xy;	\n"
"}                            \n";

const GLbyte fShaderStr[] =
"precision mediump float;\n"
"uniform sampler2D tex_y;					\n"
"uniform sampler2D tex_u;					\n"
"uniform sampler2D tex_v;					\n"
"varying vec2 tc;							\n"
"void main()                                  \n"
"{                                            \n"
"  vec4 c = vec4((texture2D(tex_y, tc).r - 16./255.) * 1.164);\n"
"  vec4 U = vec4(texture2D(tex_u, tc).r - 128./255.);\n"
"  vec4 V = vec4(texture2D(tex_v, tc).r - 128./255.);\n"
"  c += V * vec4(1.596, -0.813, 0, 0);\n"
"  c += U * vec4(0, -0.392, 2.017, 0);\n"
"  c.a = 1.0;\n"
"  gl_FragColor = c ;\n"
"}                                            \n";

- (void)setShaders
{
    GLint vertCompiled, fragConpiled;
    GLint linked;
    
    v = glCreateShader(GL_VERTEX_SHADER);
    f = glCreateShader(GL_FRAGMENT_SHADER);
    
    const char *vv = (const char*)vShaderStr;
    const char *ff = (const char*)fShaderStr;
    
    glShaderSource(v, 1, &vv, NULL);
    glShaderSource(f, 1, &ff, NULL);
    
    glCompileShader(v);
    glGetShaderiv(v, GL_COMPILE_STATUS, &vertCompiled);
    
    glCompileShader(f);
    glGetShaderiv(f, GL_COMPILE_STATUS, &fragConpiled);
    
    p = glCreateProgram();
    
    glAttachShader(p, v);
    glAttachShader(p, f);
    
    glBindAttribLocation(p, ATTRIB_VERTEX, "vPosition");
    glBindAttribLocation(p, ATTRIB_TEXTURE, "a_texCoord");
    
    glLinkProgram(p);
    glGetProgramiv(p, GL_LINK_STATUS, &linked);
    
    glUseProgram(p);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if(b_active == YES)
    {        
        IRDMediaSample *mediaSample;
        if([videoDataBuffer getMediaSample:&mediaSample] == RC_OK)
        {
            char *YUVData;
            mediaSample->GetBuffer(&YUVData);
            
            char *Y = YUVData + MEDIA_HEADER_LEN;
            char *U = Y + width*height;
            char *V = U + width*height/4;
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, textureY);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, Y);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, textureU);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, U);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, textureV);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, V);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glClearColor(0.6, 0.6, 0.0, 1.0);
            
            static const GLfloat squareVertices[] = {
                -1.0f,  1.0f,
                -1.0f, -1.0f,
                1.0f,  1.0f,
                1.0f, -1.0f
            };
            
            static const GLfloat coordVertices[] = {
                0.0f,   1.0f,
                1.0f,   1.0f,
                0.0f, 0.0f,
                1.0f,  0.0f,
            };
            
            glClear(GL_COLOR_BUFFER_BIT);
            
            glUseProgram(p);
            
            GLuint textureUniformY = glGetUniformLocation(p, "tex_y");
            GLuint textureUniformU = glGetUniformLocation(p, "tex_u");
            GLuint textureUniformV = glGetUniformLocation(p, "tex_v");
            
            glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            
            glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, 0, 0, coordVertices);
            glEnableVertexAttribArray(ATTRIB_TEXTURE);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, textureY);
            glUniform1i(textureUniformY, 0);
            
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, textureU);
            glUniform1i(textureUniformU, 1);
            
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, textureV);
            glUniform1i(textureUniformV, 2);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            glFlush();
            
            mediaSample->Release();
        }
    }
}

- (int)initWithCodecParam:(codecParam *)param VideoDataBuffer:(MediaBuffer *)v_buf AudioDataBuffer:(MediaBuffer *)a_buf
{
    if(param == NULL || v_buf == NULL || a_buf == NULL)
    {
        return RC_INVALID_ARG;
    }
    displayView = (__bridge GLKView*)(param->displayView);
    context = (__bridge EAGLContext*)(param->context);
    top = param->top;
    left = param->left;
    bottom = param->bottom;
    right = param->right;
    width = param->width;
    height = param->height;
    fps_den = param->fps_den;
    fps_num = param->fps_num;
    
    videoDataBuffer = v_buf;
    audioDataBuffer = a_buf;
    
    dataFormat.mSampleRate = param->sampleRate;
    dataFormat.mReserved = 0;
    dataFormat.mFormatID = kAudioFormatLinearPCM;
    dataFormat.mChannelsPerFrame = param->chanel;
    
    if(param->sampleBit == 8)
    {
        dataFormat.mFormatFlags = kAudioFormatFlagIsPacked;
    }
    else
    {
        dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    }
    dataFormat.mFramesPerPacket = 1;
    dataFormat.mBytesPerFrame = param->chanel * (param->sampleBit/8);
    dataFormat.mBytesPerPacket = dataFormat.mBytesPerFrame;
    dataFormat.mBitsPerChannel = param->sampleBit;
    
    AudioQueueNewOutput(&(dataFormat), bufferCallBack, (__bridge void *)self, CFRunLoopGetMain(), kCFRunLoopCommonModes, 0, &queue);
    AudioQueueAllocateBuffer(queue, MAX_AUDIO_FRAME_SIZE, &buffers[0]);
    AudioQueueAllocateBuffer(queue, MAX_AUDIO_FRAME_SIZE, &buffers[1]);
    AudioQueueAllocateBuffer(queue, MAX_AUDIO_FRAME_SIZE, &buffers[2]);
    
    float gain = 1.0;
    AudioQueueSetParameter(queue, kAudioQueueParam_Volume, gain);
    
    b_active = NO;
    
    return RC_OK;
}

- (void)audioThreadProc
{
    while([audioDataBuffer getCurrentCount] < 3)
    {
        //NSLog(@"No enough data");
    }
    [self fillAudioQueueBuffer:buffers[0]];
    [self fillAudioQueueBuffer:buffers[1]];
    [self fillAudioQueueBuffer:buffers[2]];
    AudioQueueStart(queue, NULL);
    
    b_active = YES;
    [EAGLContext setCurrentContext:context];
    glGenTextures(1, &textureY);
    glGenTextures(1, &textureU);
    glGenTextures(1, &textureV);
    [self setShaders];
    displayView.delegate = self;
}

- (int)start
{
//    buffers[0]->mAudioDataByteSize = 1;
//    AudioQueueEnqueueBuffer(queue, buffers[0], 0, nil);
//    
//    buffers[1]->mAudioDataByteSize = 1;
//    AudioQueueEnqueueBuffer(queue, buffers[1], 0, nil);
//    
//    buffers[2]->mAudioDataByteSize = 12;
//    AudioQueueEnqueueBuffer(queue, buffers[2], 0, nil);
//    
//    AudioQueueStart(queue, NULL);
//    b_active = YES;
//    [EAGLContext setCurrentContext:context];
//    glGenTextures(1, &textureY);
//    glGenTextures(1, &textureU);
//    glGenTextures(1, &textureV);
//    [self setShaders];
//    displayView.delegate = self;
    audioStart = [[NSThread alloc] initWithTarget:self selector:@selector(audioThreadProc) object:nil];
    [audioStart start];
    
    return RC_OK;
}

- (int)stop
{
    AudioQueueStop(queue, true);
    b_active = NO;
    return RC_OK;
}

@end