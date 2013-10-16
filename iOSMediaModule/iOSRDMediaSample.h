//
//  iOSMediaSample.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iOSMediaModulePub.h"

/**
 * 媒体数据内存类，继承媒体数据内存接口类IRDMediaSample
 */
class iOSRDMediaSample : public IRDMediaSample
{
private:
    char *buffer;
    int length;
    int actualLength;
    int refCount;
    NSLock *lock;
    
public:
    /**
     * 媒体数据内存类构造函数
     * @param len 媒体数据内存buffer区长度
     */
    iOSRDMediaSample(int len);
    
    /**
     * 媒体数据内存类析构函数
     */
    ~iOSRDMediaSample();
    
    /**
	 * 获取sample的内存
     * @param buf sample数据指针
     * @return 成功RC_OK
     */
    int GetBuffer(char** buf);
    
    /**
	 * 获取sample的分配长度
     * @return >0 成功 <=0 失败
     */
    int GetLength();
    
    /**
	 * 获取sample的数据长度
     * @return >=0 成功; <0 失败
     */
    int GetActualLength();
    
    /**
	 * 增加引用计数
     * @return
     */
    int AddRef();
    
    /**
     * 获取引用计数
     * @return 引用计数
     */
    int GetRef();
    
    /**
	 * 减少引用计数
     * @return
     */
    int Release();
    
    /**
     * 媒体数据内存重分配
     * @pram len 重新分配的媒体数据内存长度
     * @return 成功则返回RC_OK；否则返回值小于0
     */
    int ReAlloc(int len);
};