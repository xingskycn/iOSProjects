//
//  Common.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-12.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#ifndef iOSMediaModule_Common_h
#define iOSMediaModule_Common_h

#define MEDIA_HEADER_LEN (sizeof(int64_t)*2 + sizeof(int)*2)
#define MAX_AUDIO_FRAME_SIZE 1024

typedef struct
{
    int64_t startTime;
    int64_t endTime;
    int bKey;
    int bufLen;
}MediaHeader;

#endif
