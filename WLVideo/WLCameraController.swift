//
//  WLCameraController.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/11.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation
import Photos

class WLCameraController: UIViewController {
    
    var manager: WLCameraManager!
    let previewImageView = UIImageView()
    var videoPlayer: WLVideoPlayer?
    let controlView = WLCameraControl.init(frame: CGRect(x: 0, y: screenHeight - 150, width: screenWidth, height: 150))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = WLCameraManager(superView: self.view)
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.staruRunning()
        manager.focusAt(self.view.center)
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.black
        self.view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(focus(_:))))
        self.view.addGestureRecognizer(UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(_:))))
        
        videoPlayer = WLVideoPlayer(frame: self.view.bounds)
        videoPlayer?.isHidden = true
        self.view.addSubview(videoPlayer!)
        
        previewImageView.frame = self.view.bounds
        previewImageView.backgroundColor = UIColor.black
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.isHidden = true
        self.view.addSubview(previewImageView)
        
        view.addSubview(controlView)
        controlView.tapBlock = { [weak self] in
            guard let `self` = self else { return }
            self.pickImage()
        }
        controlView.longPressBlock = { [weak self] state in
            guard let `self` = self else { return }
            if state == .begin {
                self.startRecordVideo()
                self.manager.repareForZoom()
            } else if state == .end {
                self.endRecordVideo()
            }
        }
        controlView.retakeBlock = { [weak self] in
            guard let `self` = self else { return }
            self.retake()
        }
        controlView.longPressChangeBlock = { [weak self] in
            guard let `self` = self else { return }
            let sh = Double(screenHeight) * 0.15
            let zoom = ($0 / sh) + 1
            self.manager.zoom(zoom)
        }
        controlView.changeCameraBlock = { [weak self] in
            guard let `self` = self else { return }
            self.manager.changeCamera()
        }
        controlView.dismissBlock = { [weak self] in
            guard let `self` = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func pickImage() {
        manager.pickImage { [weak self] (imageUrl) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.previewImageView.image = UIImage.init(contentsOfFile: imageUrl)
                self.previewImageView.isHidden = false
                self.controlView.showCompleteAnimation()
            }
        }
    }
    
    func startRecordVideo() {
        manager.startRecordingVideo()
    }
    
    func endRecordVideo() {
        manager.endRecordingVideo { [weak self] (videoUrl) in
            guard let `self` = self else { return }
            let url = URL.init(fileURLWithPath: videoUrl)
            self.videoPlayer?.videoUrl = url
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: {
                self.videoPlayer?.isHidden = false
                self.videoPlayer?.play()
                self.controlView.showCompleteAnimation()
            })
        }
    }
    
    @objc func focus(_ ges: UITapGestureRecognizer) {
        let focusPoint = ges.location(in: self.view)
        manager.focusAt(focusPoint)
    }
    
    @objc func pinch(_ ges: UIPinchGestureRecognizer) {
        guard ges.numberOfTouches == 2 else { return }
        if ges.state == .began {
            self.manager.repareForZoom()
        }
        self.manager.zoom(Double(ges.scale))
    }
    
    func retake() {
        self.previewImageView.isHidden = true
        self.videoPlayer?.isHidden = true
        self.videoPlayer?.pause()
    }
    
}
