//
//  VideoBuffer.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-9.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <foundation/foundation.h>
#import "iOSRDMediaSample.h"

@interface MediaBuffer : NSObject
{
    IRDMediaSample **mediaSample;
    int maxCount;
    int currentCount;
    NSLock *lock;
}

/**
 * MediaBuffer初始化
 * @param maxCnt MediaBuffer最大buffer数量
 * @return MediaBuffer对象
 */
- (id)initWithMaxCount : (int)maxCnt;

/**
 * 从MediaBuffer中获取媒体数据内存
 * @param sample 存储获取到的媒体数据内存
 * @return 成功则返回RC_OK；否则返回值小于0
 */
- (int)getMediaSample : (IRDMediaSample**)sample;

/**
 * 将媒体数据内存放入MediaBuffer
 * @param sample 要放入MediaBuffer的媒体数据内存
 * @return 成功则返回RC_OK；否则返回值小于0
 */
- (int)putMediaSample : (IRDMediaSample*)sample;

/**
 * 获取MediaBuffer中可用的buffer个数
 * @param cnt 存储获取到的buffer个数
 * @return 成功则返回RC_OK；否则返回值小于0
 */
- (int)getCurrentCount : (int*)cnt;

- (int)getCurrentCount;

@end