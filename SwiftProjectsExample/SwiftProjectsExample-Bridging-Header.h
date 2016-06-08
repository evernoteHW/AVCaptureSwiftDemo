//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "avformat.h"
#import "avcodec.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#import "X264Manager.h"
// 使用x264 必须要include的头文件
#include <stdint.h>
#include <inttypes.h>
#include "x264_config.h"
#include "x264.h"

//#import "AACEncoder.h"
#import "H264HwEncoderImpl.h"
#import "UIUtils.h"

#import "NSLogger.h"
#import "VCSimpleSession.h"
#import "KxMovieViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "KxMovieDecoder.h"
#import <Accelerate/Accelerate.h>
#include"libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"