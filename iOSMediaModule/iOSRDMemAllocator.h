//
//  iOSRDMemAllocator.h
//  iOSMediaModule
//
//  Created by liyang on 13-10-10.
//  Copyright (c) 2013年 liyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iOSMediaModulePub.h"

class iOSRDMediaSample;


/**********************************************************
 * 媒体数据内存分配类，继承媒体数据内存分配接口类IRDMemAllocator
 **********************************************************/
class iOSRDMemAllocator : public IRDMemAllocator
{
private:
    NSLock *lock;
    int sampleCount;
    int sampleSize;
    iOSRDMediaSample **mediaSample;
    
public:
    /**
     * 媒体数据内存分配类构造函数
     */
    iOSRDMemAllocator();
    
    /**
	 * 获取空闲媒体数据
     * @param psample 空闲数据指针
     * @return 成功RC_OK
     */
    int GetFreeRDMediaSample(IRDMediaSample** psample);
    
    /**
	 * 修改空闲媒体数据的大小
     * @param psample 空闲数据指针
     * @param size 空闲数据修改大小
     * @return 成功RC_OK psample的buffer被修改
     */
    int ReallocRDMediaSample(IRDMediaSample** psample,int size);
    
    /**
	 * 获取媒体分配器的参数，该接口可以多次调用
     * @param sample_cnt 媒体数据个数
     * @param sample_size 媒体数据大小
     * @return 成功RC_OK
     */
    int GetProperty(int* sample_cnt,int* sample_size);
    
    /**
	 * 设置媒体分配器的参数，该接口在媒体分配其初始化的时候调用一次，外部
     * 程序不要调用此接口
     * @param sample_cnt 媒体数据个数
     * @param sample_size 媒体数据大小
     * @return 成功RC_OK
     */
    int SetProperty(int sample_cnt,int sample_size);
    
    /**
	 * 媒体分配器内存提交，外部程序不要调用此接口
     * @return 成功RC_OK
     */
    int Commit();
    
    /**
	 * 媒体分配器内存反提交，外部程序不要调用此接口
     * @return 成功RC_OK
     */
    int DeCommit();
};
