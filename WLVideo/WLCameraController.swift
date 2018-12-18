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

enum CameraType {
    case video
    case image
}

class WLCameraController: UIViewController {
    
    var url: String?
    var type: CameraType?
    
    var completeBlock: (String, CameraType) -> () = {_,_  in }
    
    let previewImageView = UIImageView()
    var videoPlayer: WLVideoPlayer!
    var controlView: WLCameraControl!
    var manager: WLCameraManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = WLCameraManager(superView: self.view)
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.staruRunning()
        manager.focusAt(self.view.center)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.black
        self.view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(focus(_:))))
        self.view.addGestureRecognizer(UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(_:))))
        
        videoPlayer = WLVideoPlayer(frame: self.view.bounds)
        videoPlayer.isHidden = true
        self.view.addSubview(videoPlayer)
        
        previewImageView.frame = self.view.bounds
        previewImageView.backgroundColor = UIColor.black
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.isHidden = true
        self.view.addSubview(previewImageView)
        
        controlView = WLCameraControl.init(frame: CGRect(x: 0, y: screenHeight - 150, width: screenWidth, height: 150))
        controlView.delegate = self
        view.addSubview(controlView)
    }
    
    @objc func focus(_ ges: UITapGestureRecognizer) {
        let focusPoint = ges.location(in: self.view)
        manager.focusAt(focusPoint)
    }
    
    @objc func pinch(_ ges: UIPinchGestureRecognizer) {
        guard ges.numberOfTouches == 2 else { return }
        if ges.state == .began {
            manager.repareForZoom()
        }
        manager.zoom(Double(ges.scale))
    }
    
}

extension WLCameraController: WLCameraControlDelegate {
    
    func cameraControlDidComplete() {
        dismiss(animated: true) {
            self.completeBlock(self.url!, self.type!)
        }
    }
    
    func cameraControlDidTakePhoto() {
        manager.pickImage { [weak self] (imageUrl) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.type = .image
                self.url = imageUrl
                self.previewImageView.image = UIImage.init(contentsOfFile: imageUrl)
                self.previewImageView.isHidden = false
                self.controlView.showCompleteAnimation()
            }
        }
    }
    
    func cameraControlBeginTakeVideo() {
        manager.repareForZoom()
        manager.startRecordingVideo()
    }
    
    func cameraControlEndTakeVideo() {
        manager.endRecordingVideo { [weak self] (videoUrl) in
            guard let `self` = self else { return }
            let url = URL.init(fileURLWithPath: videoUrl)
            self.videoPlayer.videoUrl = url
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: {
                self.type = .video
                self.url = videoUrl
                self.videoPlayer.isHidden = false
                self.videoPlayer.play()
                self.controlView.showCompleteAnimation()
            })
        }
    }
    
    func cameraControlDidChangeFocus(focus: Double) {
        let sh = Double(screenHeight) * 0.15
        let zoom = (focus / sh) + 1
        self.manager.zoom(zoom)
    }
    
    func cameraControlDidChangeCamera() {
        manager.changeCamera()
    }
    
    func cameraControlDidClickBack() {
        self.previewImageView.isHidden = true
        self.videoPlayer.isHidden = true
        self.videoPlayer.pause()
    }
    
    func cameraControlDidExit() {
        dismiss(animated: true, completion: nil)
    }
    
}
