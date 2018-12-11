//
//  WLCameraManager.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/11.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation

class WLCameraManager: NSObject {
    
    let session = AVCaptureSession()
    
    /**视频输入设备*/
    var videoInput: AVCaptureDeviceInput!
    /**音频输入设备*/
    var audioInput: AVCaptureDeviceInput!
    
    /**预览图层*/
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var assetWriter: AVAssetWriter!
    /**音频写入*/
    var assetWriterAudioInput: AVAssetWriterInput!
    /**视频写入*/
    var assetWriterVideoInput: AVAssetWriterInput!
    
    /**视频输出*/
    var videoDataOut: AVCaptureVideoDataOutput!
    /**音频输出*/
    var audioDataOut: AVCaptureAudioDataOutput!
    /**照片输出*/
    var stillImageOutput: AVCaptureStillImageOutput!
    
    let focusImageView = UIImageView()
    var currentUrl: String!
    var showView: UIView!
    
    let videoQueue = DispatchQueue(label: "videoOutQueue")
    let voiceQueue = DispatchQueue(label: "voiceOutQueue")
    
    var isRecording: Bool = false
    var isFocusing: Bool = false
    var videoCurrentZoom: Double = 1.0
    
    let orientation = WLDeviceOrientation()
    var currentOrientation: UIInterfaceOrientation = .portrait
    
    var error: (String) -> () = {_ in }
    
    init(superView: UIView) {
        super.init()
        self.showView = superView
        
        setupCamera()
        setupView()
        
        // 开启手机方向监听
        orientation.startUpdates { [weak self] (orientation) in
            guard let self = self else { return }
            self.currentOrientation = orientation
        }
    }
    
    func staruRunning() {
        session.startRunning()
    }
    
    // 初始化相机
    func setupCamera() {
        if (session.canSetSessionPreset(.high)) {
            session.sessionPreset = .high
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = showView.layer.bounds
        showView.layer.addSublayer(previewLayer)
        
        //输入设备
        let devicesVideo = AVCaptureDevice.devices(for: .video)
        let devicesAudio = AVCaptureDevice.devices(for: .audio)
        
        guard let firstVideoDevice = devicesVideo.first,
            let firstAudioDevice = devicesAudio.first,
            let video = try? AVCaptureDeviceInput.init(device: firstVideoDevice),
            let audio = try? AVCaptureDeviceInput.init(device: firstAudioDevice)
            else {
                error("初始化相机失败")
                return
        }
        
        videoInput = video
        audioInput = audio
        
        //添加输入源
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        //视频输出
        videoDataOut = AVCaptureVideoDataOutput()
        videoDataOut.alwaysDiscardsLateVideoFrames = true
        videoDataOut.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoDataOut) {
            session.addOutput(videoDataOut)
        }
        
        //音频输出
        audioDataOut = AVCaptureAudioDataOutput()
        audioDataOut.setSampleBufferDelegate(self, queue: voiceQueue)
        if session.canAddOutput(audioDataOut) {
            session.addOutput(audioDataOut)
        }
        
        //图片输出
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
    }
    
    func setupView() {
        focusImageView.image = UIImage.init(named: "sight_video_focus")
        focusImageView.frame = CGRect(origin: .zero, size: CGSize(width: 60, height: 60))
        focusImageView.isHidden = true
        showView.addSubview(focusImageView)
    }
    
    //每次录制视频都要初始化写入
    func initializeVideoWriter() {
        let width = WLVideoConfig.videoWidth
        let height = WLVideoConfig.videoHeight
        let rotate = self.videoRotateWith(self.currentOrientation)
        
        guard let writer = try? AVAssetWriter.init(outputURL: URL.init(fileURLWithPath: currentUrl), fileType: AVFileType.mp4) else {
            error("无法写入视频")
            return
        }
        assetWriter = writer
        
        // 视频参数
        let compressionProperties = [
            AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel,
            AVVideoAllowFrameReorderingKey: false,
            AVVideoExpectedSourceFrameRateKey: 30,
            AVVideoMaxKeyFrameIntervalKey: 30,
            AVVideoAverageBitRateKey: 12 * width * height
            ] as [String : Any]
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: height * 2,
            AVVideoHeightKey: width * 2 ,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: compressionProperties
            ] as [String : Any]
        
        assetWriterVideoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: outputSettings)
        assetWriterVideoInput.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotate))
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        // 音频参数
        let audioOutputSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRatePerChannelKey: 28000,
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1]
        
        assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterAudioInput) {
            assetWriter.add(assetWriterAudioInput)
        }
        
    }
    
    // 创建一个新的文件路径
    func createFileUrl(_ type: String) -> String {
        let formate = DateFormatter()
        formate.dateFormat = "yyyyMMddHHmmss"
        let fileName = formate.string(from: Date()) + "." + type
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let filePath = path! + "/" + fileName
        return filePath
    }
    
    // 拍照调用方法
    func pickImage(complete: @escaping (String) -> ()) {
        currentUrl = createFileUrl("jpg")
        let imageOrientation = currentOrientation
        let videoConnection = stillImageOutput.connection(with: .video)
        
        stillImageOutput.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { [weak self] (buffer, error) in
            
            guard let self = self,
                let buffer = buffer,
                let imageData = AVCaptureStillImageOutput
                    .jpegStillImageNSDataRepresentation(buffer),
                let originImage = UIImage.init(data: imageData)
                else {
                    return
            }
            let rotete = self.imageRotateWith(imageOrientation)
            let newImage = WLImageRotate.rotateImage(originImage, withAngle: rotete)
            
            try? newImage.jpegData(compressionQuality: 1)?.write(to: URL.init(fileURLWithPath: self.currentUrl))
            complete(self.currentUrl)
        })
    }
    
    func startRecordingVideo() {
        currentUrl = createFileUrl("MOV")
        initializeVideoWriter()
        isRecording = true
    }
    
    func endRecordingVideo(complete: @escaping (String) -> ()) {
        if !isRecording { return }
        isRecording = false
        
        self.assetWriter.finishWriting(completionHandler: { [weak self] in
            guard let self = self else { return }
            self.assetWriter = nil
            self.assetWriterVideoInput = nil
            self.assetWriterAudioInput = nil
            complete(self.currentUrl)
        })
    }
    
    func focusAt(_ point: CGPoint) {
        if isFocusing { return }
        
        self.isFocusing = true
        self.focusImageView.center = point
        self.focusImageView.isHidden = false
        self.focusImageView.transform = CGAffineTransform.init(scaleX: 1.4, y: 1.4)
        
        lockForConfiguration { [weak self] (devide) in
            guard let self = self else { return }
            let cameraPoint = self.previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            
            if devide.isFocusModeSupported(.continuousAutoFocus) {
                devide.focusMode = .continuousAutoFocus
            }
            if devide.isFocusPointOfInterestSupported {
                devide.focusPointOfInterest = cameraPoint
            }
            
            if devide.isExposureModeSupported(.continuousAutoExposure) {
                devide.exposureMode = .continuousAutoExposure
            }
            if devide.isExposurePointOfInterestSupported {
                devide.exposurePointOfInterest = cameraPoint
            }
        }
        
        showFocusImageAnimation()
        
    }
    
    func showFocusImageAnimation() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.focusImageView.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        }
        for i in 1...5 {
            UIView.animate(withDuration: 0.1, delay: 0.2 * Double(i), animations: { [weak self] in
                guard let self = self else { return }
                self.focusImageView.alpha = CGFloat(i % 2)
            })
        }
        UIView.animate(withDuration: 0.2, delay: 1, animations: {
            self.focusImageView.alpha = 0
        }){ [weak self] _ in
            guard let self = self else { return }
            self.isFocusing = false
            self.focusImageView.isHidden = true
        }
        
    }
    
    func repareForZoom() {
        videoCurrentZoom = Double(videoInput.device.videoZoomFactor)
    }
    
    func zoom(_ mulriple: Double) {
        let videoMaxZoomFactor = min(5, videoInput.device.activeFormat.videoMaxZoomFactor)
        let toZoomFactory = max(1, Double(videoCurrentZoom) * mulriple)
        let finalZoomFactory = min(toZoomFactory, Double(videoMaxZoomFactor))
        lockForConfiguration { (device) in
            device.ramp(toVideoZoomFactor: CGFloat(finalZoomFactory), withRate: 10.0)
        }
    }
    
    // 切换摄像头
    func changeCamera() {
        let currentPosition = videoInput.device.position
        var toChangePosition = AVCaptureDevice.Position.front
        if currentPosition == .unspecified || currentPosition == .front {
            toChangePosition = .back
        }
        
        guard let toChangeDevice = getCameraDevice(toChangePosition),
            let toChangeDeviceInput = try? AVCaptureDeviceInput.init(device: toChangeDevice) else {
                error("切换摄像头失败")
                return
        }
        session.beginConfiguration()
        session.removeInput(videoInput)
        if session.canAddInput(toChangeDeviceInput) {
            session.addInput(toChangeDeviceInput)
            videoInput = toChangeDeviceInput
        }
        session.commitConfiguration()
    }
    
    func getCameraDevice(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let cameras = AVCaptureDevice.devices(for: .video)
        return cameras.first(where: { $0.position == position })
    }
    
    func lockForConfiguration(_ closure: (AVCaptureDevice) -> ()) {
        let captureDevice = self.videoInput.device
        do {
            try captureDevice.lockForConfiguration()
            closure(captureDevice)
            captureDevice.unlockForConfiguration()
        } catch {
            
        }
    }
    
    deinit {
        session.stopRunning()
    }
}

extension WLCameraManager {
    
    func imageRotateWith(_ imageOrientation: UIInterfaceOrientation) -> Double {
        let rotate: Double
        switch imageOrientation {
        case .portraitUpsideDown:
            rotate = 180
        case .landscapeLeft:
            rotate = -90
        case .landscapeRight:
            rotate = 90
        default:
            rotate = 0
        }
        return rotate
    }
    
    func videoRotateWith(_ videoOrientation: UIInterfaceOrientation) -> Double {
        let rotate: Double
        switch videoOrientation {
        case .landscapeRight:
            rotate = .pi
        case .landscapeLeft:
            rotate = 0
        case .portraitUpsideDown:
            rotate = .pi * 1.5
        default:
            rotate = .pi * 0.5
        }
        return rotate
    }
}

extension WLCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !isRecording {
            return
        }
        autoreleasepool {
            if output == videoDataOut { // 在收到视频信号之后再开始写入，防止视频前几帧黑屏
                if assetWriter.status != .writing {
                    let currentSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    assetWriter.startWriting()
                    assetWriter.startSession(atSourceTime: currentSampleTime)
                }
                if assetWriterVideoInput.isReadyForMoreMediaData {
                    assetWriterVideoInput.append(sampleBuffer)
                }
            }
            if output == audioDataOut {
                if assetWriterAudioInput.isReadyForMoreMediaData {
                    assetWriterAudioInput.append(sampleBuffer)
                }
            }
        }
    }
    
}
