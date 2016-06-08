//
//  ViewController.swift
//  AVCaptureSwiftDemo
//
//  Created by WeiHu on 16/5/20.
//  Copyright © 2016年 WeiHu. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import Foundation


@objc class ViewController: UIViewController, VCSessionDelegate{

    private var _btnConnect: UIButton!
    private var _previewView: UIView!
    private var _playVideoBtn: UIButton!
    
//    @IBOutlet weak var bgView: UIView!
//    @IBOutlet weak var connectBtn: UIButton!
    var session:VCSimpleSession = VCSimpleSession(videoSize: CGSize(width: 1280, height: 720), frameRate: 30, bitrate: 1000000, useInterfaceOrientation: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureViews()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.session.previewView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height - 87)
            self.previewView.addSubview(self.session.previewView)
            self.session.delegate = self
        }
        
//        dataWithBytes()
    }

    private func configureViews(){
        self.view.addSubview(btnConnect)
        self.view.addSubview(playVideoBtn)
        self.view.addSubview(previewView)
        self.consraintsForSubViews()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        _btnConnect = nil
        _previewView = nil
        session.delegate = nil;
    }
    
    func btnConnectTouch(sender: AnyObject) {
        switch session.rtmpSessionState {
        case .None, .PreviewStarted, .Ended, .Error:
            session.startRtmpSessionWithURL("rtmp://10.14.226.106/live", andStreamKey: "myStream")
        default:
            session.endRtmpSession()
        }
    }
    
    func connectionStatusChanged(sessionState: VCSessionState) {
        switch session.rtmpSessionState {
        case .Starting:
            btnConnect.setTitle("Connecting", forState: .Normal)
            
        case .Started:
            btnConnect.setTitle("Disconnect", forState: .Normal)
            
        default:
            btnConnect.setTitle("Connect", forState: .Normal)
        }
    }
    
    
     func btnFilterTouch(sender: AnyObject) {
        switch self.session.filter {
            
        case .Normal:
            self.session.filter = .Gray
            
        case .Gray:
            self.session.filter = .InvertColors
            
        case .InvertColors:
            self.session.filter = .Sepia
            
        case .Sepia:
            self.session.filter = .Fisheye
            
        case .Fisheye:
            self.session.filter = .Glow
            
        case .Glow:
            self.session.filter = .Normal
        }
    }

    func playRecordAction() {
    
        
        let vc = KxMovieViewController.movieViewControllerWithContentPath("rtmp://10.14.226.106/live/myStream", parameters: nil)
        self.presentViewController(vc as! KxMovieViewController, animated: true, completion: nil)

    }
}
//UI
private extension ViewController{
    // MARK: - getter and setter
   
    private var btnConnect: UIButton {
        get{
            if _btnConnect == nil{
                _btnConnect = UIButton()
                _btnConnect.translatesAutoresizingMaskIntoConstraints = false
                _btnConnect.backgroundColor = UIColor.orangeColor()
                _btnConnect.setTitleColor(UIColor.blackColor(), forState: .Normal)
                _btnConnect.setTitle("Connecting", forState: .Normal)
                _btnConnect.titleLabel?.textAlignment = .Center
                _btnConnect.titleLabel?.font = UIFont.systemFontOfSize(14)
                _btnConnect.addTarget(self, action: #selector(ViewController.btnConnectTouch), forControlEvents: .TouchUpInside)
            }
            return _btnConnect
            
        }
        set{
            _btnConnect = newValue
        }
    }
   
    private var previewView: UIView {
        get{
            if _previewView == nil{
                _previewView = UIView()
                _previewView.translatesAutoresizingMaskIntoConstraints = false
                _previewView.backgroundColor = UIColor.yellowColor().colorWithAlphaComponent(0.5)
            }
            return _previewView
            
        }
        set{
            _previewView = newValue
        }
    }
    
    private var playVideoBtn: UIButton {
        get{
            if _playVideoBtn == nil{
                _playVideoBtn = UIButton()
                _playVideoBtn.translatesAutoresizingMaskIntoConstraints = false
                _playVideoBtn.backgroundColor = UIColor.orangeColor()
                _playVideoBtn.setTitleColor(UIColor.blackColor(), forState: .Normal)
                _playVideoBtn.setTitle("Connecting", forState: .Normal)
                _playVideoBtn.titleLabel?.textAlignment = .Center
                _playVideoBtn.titleLabel?.font = UIFont.systemFontOfSize(14)
                _playVideoBtn.addTarget(self, action: #selector(ViewController.playRecordAction), forControlEvents: .TouchUpInside)
            }
            return _playVideoBtn
            
        }
        set{
            _playVideoBtn = newValue
        }
    }
    // MARK: - consraintsForSubViews
    private func consraintsForSubViews() {
        // align previewView from the left and right
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": previewView]));
        
        // align previewView from the top and bottom
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-87-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": previewView]));
        
        // align btnConnect from the left and right
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[view(==140)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": btnConnect]));
        
        // align btnConnect from the top and bottom
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topView]-10-[view(==32)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["topView":previewView,"view": btnConnect]));
        

        self.view.addConstraint(NSLayoutConstraint(item: btnConnect, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: previewView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0))
        
        // align playVideoBtn from the left and right
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[leftView]-10-[view(==50)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["leftView":btnConnect,"view": playVideoBtn]));
        
        // align playVideoBtn from the top and bottom
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topView]-10-[view(==32)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["topView":previewView,"view": playVideoBtn]));
    }

}
