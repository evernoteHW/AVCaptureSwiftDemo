//
//  MovieDecoeder.swift
//  AVCaptureSwiftDemo
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
    
    var path: String = ""
    var isEOF: Bool = false
    var position: CGFloat = 0.0
    var duration: CGFloat = 0.0
    var fps: CGFloat = 0.0
    var sampleRate: CGFloat = 0.0
    var frameWidth: Int = 0
    var frameHeight: Int = 0
    var audioStreamsCount: Int = 0
    var selectedAudioStream: Int = 0
    var subtitleStreamsCount: Int = 0
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
    var videoCodecCtx: AVCodecContext?
    var audioCodecCtx: AVCodecContext?
    var subtitleCodecCtx: AVCodecContext?
    var videoFrame: AVFrame?
    var audioFrame: AVFrame?
    var videoStream: Int = 0
    var audioStream: Int = 0
    var subtitleStream: Int = 0
    var picture: AVPicture?
    var pictureValid: Bool = false
    var videoTimeBase: CGFloat = 0.0
    var audioTimeBase: CGFloat = 0.0
    var videoStreams: NSArray?
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
        if self.openInput(path) == .None{
            subtitleStream = -1
            if openVideoStream() != .None && openAudioStream() != .None{
            
            }
        }else{
        
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
//        videoStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_VIDEO);
        
       

        
        return errCode;

    }
    func openAudioStream() -> MovieError  {
        
        return .None
    }
    
    func collectStreams(formatCtx: AVFormatContext,codecType: AVMediaType) -> NSArray {
        let ma = NSMutableArray()
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
        if let provider = CGDataProviderCreateWithCFData(rgb),let colorSpace = CGColorSpaceCreateDeviceRGB(){
            if let imageRef = CGImageCreate(width, height, 8, 24, linesize, colorSpace, CGBitmapInfo.ByteOrderDefault, provider, nil, true, CGColorRenderingIntent.RenderingIntentDefault){
                return UIImage(CGImage: imageRef)
            }
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
        if let provider = CGDataProviderCreateWithCFData(picture){
            if let imageRef = CGImageCreateWithJPEGDataProvider(provider, nil, true, CGColorRenderingIntent.RenderingIntentDefault){
                return UIImage(CGImage: imageRef)
            }
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