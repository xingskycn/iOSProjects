/*************************************************
 Copyright (C), 2013-, redcdn Tech. Co., Ltd.
 Author:		www.redcdn.cn
 Version:		1.0
 Date:			2013-9-22
 Description:    iOSMediaModule具有采集、编码、解码、渲染功能
 本文件主要定义了iOSMediaModule提供的接口
 *************************************************/

#ifndef __iOSMediaModule__iOSMediaModulePub__
#define __iOSMediaModule__iOSMediaModulePub__

#include <stdint.h>

//函数返回值
enum RET_CODE
{
    RC_UNKNOWN = -5,
    RC_ENCODE_ERROR = -4,
    RC_VIDEO_DECODE_ERROR = -3,
	RC_OUT_MEM = -2,
	RC_INVALID_ARG = -1,
	RC_OK,
};

//媒体类型
enum iOS_MEDIA_TYPE
{
    iOS_MEDIA_TYPE_VIDEO = 0,
    iOS_MEDIA_TYPE_AUDIO,
};

//视频编解码器
enum VIDEO_CODEC
{
	VIDEO_CODEC_H264 = 0,
};

//音频编解码器
enum AUDIO_CODEC
{
	AUDIO_CODEC_G711_ALAW = 0,
    AUDIO_CODEC_G711_ULAW,
};

enum iOS_CAPTURE_DEVICE
{
    CAPTURE_DEVICE_BACK = 0,	///<背板摄像头
	CAPTURE_DEVICE_FRONT,		///<前摄像头
};

enum iOS_PIXEL_FORMAT
{
    IOS_PIXEL_FORMAT_420YpCbCr8BiPlanarVideoRange = 0,
	IOS_PIXEL_FORMAT_420YpCbCr8BiPlanarFullRange,
	IOS_PIXEL_FORMAT_32BGRA,
};

typedef struct codecParam
{
    bool b_enc;
    
    //video codec param
    int width;
    int height;
	int fps_num;		///<帧率-分子
	int fps_den;		///<帧率-分母
    enum VIDEO_CODEC video_codec_id;
    enum iOS_CAPTURE_DEVICE capture_device_id;
	enum iOS_PIXEL_FORMAT pix_fmt;  ///<固定使用IOS_PIXEL_FORMAT_420YpCbCr8BiPlanarFullRange
    int video_bitrate;  ///bps
    
    //audio codec param
    int sampleRate;
	int sampleBit;
	int chanel;
	int audio_bitrate;	///bps
	enum AUDIO_CODEC audio_codec_id;
    
    //render param
    void *displayView;  ///<图象叠加句柄，在iOS中为GLKView
    void *context;
    int top;
    int left;
    int bottom;
    int right;
}codecParam;

/************************************************************************
 * 媒体数据内存，引用计数非常重要，调用分配其的GetFreeRDMediaSample引用计数
 * 自动加1，将媒体数据传递给其他模块使用，先调用下AddRef再使用，使用完毕后
 * 一定要调用Release，否则就无法再得到空闲sample
 ************************************************************************/
class IRDMediaSample
{
public:
	/**
	 * 获取sample的内存
     * @param buf sample数据指针
     * @return 成功RC_OK
     */
	virtual int GetBuffer(char** buf)=0;
    
	/**
	 * 获取sample的分配长度
     * @return >0 成功 <=0 失败
     */
	virtual int GetLength()=0;
    
	/**
	 * 获取sample的数据长度
     * @return >=0 成功; <0 失败
     */
	virtual int GetActualLength()=0;
    
	/**
	 * 增加引用计数
     * @return
     */
	virtual int AddRef()=0;
    
	/**
	 * 减少引用计数
     * @return
     */
	virtual int Release()=0;
};

/************************************************************************
 * 媒体分配器将媒体数据内存池化，调用者可以设置内存池的参数，获取空闲sample
 * 重新调整sample大小，以及申请内存和析构内存
 ************************************************************************/
class IRDMemAllocator
{
public:
	/**
	 * 获取空闲媒体数据
     * @param psample 空闲数据指针
     * @return 成功RC_OK
     */
	virtual int GetFreeRDMediaSample(IRDMediaSample** psample)=0;
    
	/**
	 * 修改空闲媒体数据的大小
     * @param psample 空闲数据指针
     * @param size 空闲数据修改大小
     * @return 成功RC_OK psample的buffer被修改
     */
	virtual int ReallocRDMediaSample(IRDMediaSample** psample,int size)=0;
    
	/**
	 * 获取媒体分配器的参数，该接口可以多次调用
     * @param sample_cnt 媒体数据个数
     * @param sample_size 媒体数据大小
     * @return 成功RC_OK
     */
	virtual int GetProperty(int* sample_cnt,int* sample_size)=0;
    
	/**
	 * 设置媒体分配器的参数，该接口在媒体分配其初始化的时候调用一次，外部
     * 程序不要调用此接口
     * @param sample_cnt 媒体数据个数
     * @param sample_size 媒体数据大小
     * @return 成功RC_OK
     */
	virtual int SetProperty(int sample_cnt,int sample_size)=0;
    
	/**
	 * 媒体分配器内存提交，外部程序不要调用此接口
     * @return 成功RC_OK
     */
	virtual int Commit()=0;
    
	/**
	 * 媒体分配器内存反提交，外部程序不要调用此接口
     * @return 成功RC_OK
     */
	virtual int DeCommit()=0;
};

/************************************************************************
 *  数据回调接口，iOSMediaModule实现此接口，mediastream2通过此接口将数据传入
 *  iOSMediaModule进行解码和渲染，另外mediastream2也需要实现一个此接口，以便
 *  iOSMediaModule将采集和编码的数据给传输模块进行分发
 ************************************************************************/
class IRDReceiverCallBack
{
public:
	/**
	 * 投递媒体数据
     * @param buf 媒体数据指针
     * @param buf_len 媒体数据长度
     * @param b_key 视频数据是否是关键帧，音频数据忽略
     * @param startTime,endTime媒体数据的起始和结束时间，单位ms
     * @param mediaType媒体数据类型
     * @return
     */
	virtual int onPostFrame(char *buf, int buf_len, bool b_key, int64_t startTime, int64_t endTime, iOS_MEDIA_TYPE mediaType) = 0;
};

/************************************************************************
 * 媒体控制接口，mediastream通过此接口控制iOSMediaModule
 ************************************************************************/
class IRDMediaControl
{
public:
	/**
	 * 初始化媒体控制器
     * @param codecPam 编解码参数
     * @param cb mediastream2实现的媒体回调接口，采集和编码的数据通过此接口发送给发送模块
     * @param sample_cnt sample个数，用于分配器创建
     * @param sample_size sample大小，用于分配器创建
     * @return
     */
	virtual int initialize(codecParam *param, IRDReceiverCallBack *cb, int sample_cnt, int sample_size) = 0;
    
	/**
	 * 反初始化媒体控制器
     */
	virtual int release() = 0;
    
	/**
	 * 启动媒体控制器
     */
	virtual int start() = 0;
    
	/**
	 * 停止媒体控制器
     */
	virtual int stop() = 0;
    
	/**
	 * 获取iOSMediaModule的媒体回调接口
     * @return NULL失败，非NULL成功
     */
	virtual IRDReceiverCallBack* getReceiverCallBcak() = 0;
    
	/**
	 * 获取iOSMediaModule的媒体存储分配器
     * @return NULL失败，非NULL成功
     */
	virtual IRDMemAllocator* getRDMediaAllocator() = 0;
};

/**
 * 创建媒体控制器
 * @return  NULL 失败，成功IRDMediaControl指针
 */
IRDMediaControl* create_iOSRDMediaModule();

/**
 * 析构媒体控制器
 * @param mediaControl 媒体控制器指针
 */
int destroy_iOSRDMediaModule(IRDMediaControl* mediaControl);

#endif /* defined(__iOSMediaModule__iOSMediaModulePub__) */
