//
//  MovieDecoeder.swift
//  SwiftProjectsExample
//
//  Created by WeiHu on 16/6/6.
//  Copyright © 2016年 WeiHu. All rights reserved.
//

import UIKit
////////////////////////////////////////////////////////////////////////////////////////////////
enum MovieError {
    case None
    case OpenFile
    case StreamInfoNotFound
    case StreamNotFound
    case CodecNotFound
    case OpenCodec
    case AllocateFrame
    case SetupScaler
    case ReSampler
    case UnSupported        //不支持
}
enum MovieFrameType{
    case Audio
    case Video
    case Artwork
    case Subtitle
}
enum VideoFrameFormat{
    case RGB
    case YUV
}
////////////////////////////////////////////////////////////////////////////////////////////////

typealias SwsContext = COpaquePointer

class MovieDecoeder: NSObject {
    let AV_NOPTS_VALUE: UInt64 = 0x8000000000000000
//    let AV_TIME_BASE: Int = 1000000
    var path: String = ""
    var isEOF: Bool = false
    var position: CGFloat = 0{
        didSet{
            isEOF = false
            if videoStream != -1 {
                let ts = (Int64)(position / videoTimeBase)
                avformat_seek_file(formatCtx, videoStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
                avcodec_flush_buffers(videoCodecCtx!);
            }
            
            if audioStream != -1 {
                let ts = (Int64)(position / audioTimeBase);
                avformat_seek_file(formatCtx, audioStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
                avcodec_flush_buffers(audioCodecCtx!);
            }
        }

    }
    var duration: CGFloat = 0{
        didSet{
            if UInt64(formatCtx.memory.duration) == AV_NOPTS_VALUE{
                duration = CGFloat.max
            }else{
                duration = CGFloat(formatCtx.memory.duration)/CGFloat(AV_TIME_BASE)
            }
        }
    }
    var fps: CGFloat = 0.0
    var sampleRate: Int32 = 0{
        didSet{
            if let _audioCodecCtx = audioCodecCtx{
                sampleRate = _audioCodecCtx.memory.sample_rate
            }
        }
    }
    var frameWidth: Int32 = 0{
        didSet{
            if let _videoCodecCtx = videoCodecCtx{
                frameWidth = _videoCodecCtx.memory.width
            }
        }
    }
    var frameHeight: Int32 = 0{
        didSet{
            if let _videoCodecCtx = videoCodecCtx{
                frameHeight = _videoCodecCtx.memory.height
            }
        }
    }
    var audioStreamsCount: Int = 0
    var selectedAudioStream: Int = 0{
        didSet{
            if  audioStream == -1 {
                selectedAudioStream = -1
            }
        }
    }
    var subtitleStreamsCount: Int = 0{
        didSet{
            if let _subtitleStreams = subtitleStreams{
                subtitleStreamsCount = _subtitleStreams.count
            }
        }
    }
    var selectedSubtitleStream: Int = 0
    var validVideo: Bool = false
    var validAudio: Bool = false
    var validSubtitles: Bool = false
    var info: NSDictionary?
    var videoStreamFormatName: String = ""
    var isNetwork: Bool = false
    var startTime: CGFloat = 0.0
    var disableDeinterlacing: Bool = false
    var interruptCallback: MovieDecoderInterruptCallback?
    
    var formatCtx: UnsafeMutablePointer<AVFormatContext> = avformat_alloc_context()
    var videoCodecCtx: UnsafeMutablePointer<AVCodecContext>?
    var audioCodecCtx: UnsafeMutablePointer<AVCodecContext>?
    var subtitleCodecCtx: UnsafeMutablePointer<AVCodecContext>?
    var videoFrame: AVFrame?
    var audioFrame: AVFrame?
    var videoStream: Int32 = 0
    var audioStream: Int32 = 0
    var subtitleStream: Int = 0
    var picture: AVPicture?
    var pictureValid: Bool = false
    var videoTimeBase: CGFloat = 0.0
    var audioTimeBase: CGFloat = 0.0
    var videoStreams: [NSNumber]?
    var audioStreams: NSArray?
    var subtitleStreams: NSArray?
    var swrBufferSize: Int = 0
    var videoFrameFormat: VideoFrameFormat?
    var artworkStream: Int = 0
    var subtitleASSEvents: Int = 0
    var _swrContext: SwsContext?
    var swrBuffer: AnyObject?

    
    override init() {
        super.init()
        
        av_register_all()
        av_log_set_callback { (context, level, format, args) in
            
        }
        avformat_network_init()
    }
    func openFile(path : String = "",error: NSError) {
        self.path = path
        
        isNetwork = UIUtils.isNetworkPath(path)
        if isNetwork{
            avformat_network_init()
        }
        var errCode = self.openInput(path)
        if errCode == .None{
            subtitleStream = -1
            let videoErr = openVideoStream()
            let audioErr = openAudioStream()
            if videoErr != .None && audioErr != .None{
                errCode = videoErr
            }
        }else{
            subtitleStreams = collectStreams(formatCtx, codecType: AVMEDIA_TYPE_SUBTITLE)
        }

    }
    func openInput(path: String = "") -> MovieError{
        if let _ = interruptCallback{
            
            var cb = AVIOInterruptCB()
            cb.callback = ({(callback) -> Int32 in
                return 0
            })
            formatCtx.memory.interrupt_callback = cb
        }
        //检测了文件的头部
        if avformat_open_input(&formatCtx, path.cStringUsingEncoding(NSUTF8StringEncoding)!, nil, nil) < 0{
            avformat_free_context(formatCtx)
            return .OpenFile
        }
        //检测了文件的流
        if avformat_find_stream_info(formatCtx, nil) < 0 {
            avformat_close_input(&formatCtx)
            return .StreamInfoNotFound
        }
         av_dump_format(formatCtx, 0, (path as NSString).lastPathComponent.cStringUsingEncoding(NSUTF8StringEncoding)!, 0)
        
        return .None
    }
    func openVideoStream() -> MovieError  {
        let errCode: MovieError = .StreamInfoNotFound
        videoStream = -1;
        artworkStream = -1;
        videoStreams = collectStreams(formatCtx, codecType: AVMEDIA_TYPE_VIDEO)
//        for  n in videoStreams!{
//            if (formatCtx.memory.streams[n.integerValue] & AV_DISPOSITION_ATTACHED_PIC) == 0{
//            
//            }
//        }
       

        
        return errCode;

    }
    func openAudioStream() -> MovieError  {
        
        return .None
    }
    
    func collectStreams(formatCtx: UnsafeMutablePointer<AVFormatContext>,codecType: AVMediaType) -> [NSNumber] {
        let ma = [NSNumber]()
//        for index in 0...formatCtx.nb_streams-1  {
//            if codecType == formatCtx.streams.advancedBy(i){
//            
//            }
//        }
//            for (NSInteger i = 0; i < formatCtx->nb_streams; ++i)
//            if (codecType == formatCtx->streams[i]->codec->codec_type)
//            [ma addObject: [NSNumber numberWithInteger: i]];
//            return [ma copy];
    
        return ma
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////

class MovieFrame: NSObject {
    var type: MovieFrameType = .Audio
    var position: CGFloat = 0
    var duration: CGFloat = 0
}
class AudioFrame: MovieFrame {
    var samples: NSData?
    override init() {
        super.init()
        self.type = .Audio
    }
}
class VideoFrame: MovieFrame {
    var format: VideoFrameFormat = .RGB
    var width: Int = 0
    var height: Int = 0
    
    override init() {
        super.init()
        self.type = .Video
    }
}

class VideoFrameRGB: VideoFrame {
    var linesize: Int = 0
    var rgb: NSData?
    func asImage() -> UIImage? {
        if let provider = CGDataProviderCreateWithCFData(rgb),
            let colorSpace = CGColorSpaceCreateDeviceRGB(),
            let imageRef = CGImageCreate(width, height, 8, 24, linesize, colorSpace, CGBitmapInfo.ByteOrderDefault, provider, nil, true, CGColorRenderingIntent.RenderingIntentDefault){
                return UIImage(CGImage: imageRef)
        }
        return nil
    }
    override init() {
        super.init()
        self.format = .RGB
    }
}

class VideoFrameYUV: VideoFrame {
    var luma: NSData?
    var chromaB: NSData?
    var chromaR: NSData?
    
    override init() {
        super.init()
        self.format = .YUV
    }
}

class ArtworkFrame: MovieFrame {
    var picture: NSData?
    func asImage() -> UIImage? {
        if let provider = CGDataProviderCreateWithCFData(picture),
            let imageRef = CGImageCreateWithJPEGDataProvider(provider, nil, true, CGColorRenderingIntent.RenderingIntentDefault){
            return UIImage(CGImage: imageRef)
        }
        return nil
    }

    override init() {
        super.init()
    }
}
typealias MovieDecoderInterruptCallback = () -> Void

class SubtitleFrame: MovieFrame {
    var text: String = ""
    override init() {
        super.init()
        self.type = .Subtitle
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////