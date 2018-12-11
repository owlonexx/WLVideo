//
//  WLCameraControl.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/11.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit

enum LongPressState {
    case begin
    case end
}


class WLCameraControl: UIView {
    
    typealias TapBlock = () -> ()
    typealias LongPressBlock = (LongPressState) -> ()
    
    var tapBlock: TapBlock = {}
    var longPressBlock: LongPressBlock = {_ in }
    var longPressChangeBlock: (Double) -> () = {_ in }
    var retakeBlock: () -> () = {}
    var changeCameraBlock: () -> () = {}
    var dismissBlock: () -> () = {}
    
    let videoLength: Double = WLVideoConfig.videoLength
    var recordTime: Double = 0
    
    let cameraButton = UIView()
    let centerView = UIView()
    let progressLayer = CAShapeLayer()
    
    let retakeButton = UIButton()
    let takeButton = UIButton()
    
    let exitButton = UIButton()
    let changeCameraButton = UIButton()
    
    var timer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCameraButton()
        
        retakeButton.frame = cameraButton.frame
        retakeButton.isHidden = true
        retakeButton.setBackgroundImage(UIImage.init(named: "icon_return"), for: .normal)
        retakeButton.addTarget(self, action: #selector(retakeButtonClick), for: .touchUpInside)
        self.addSubview(retakeButton)
        
        takeButton.frame = cameraButton.frame
        takeButton.isHidden = true
        takeButton.setBackgroundImage(UIImage.init(named: "icon_finish"), for: .normal)
        takeButton.addTarget(self, action: #selector(takeButtonClick), for: .touchUpInside)
        self.addSubview(takeButton)
        
        changeCameraButton.setImage(UIImage.init(named: "change_camera"), for: .normal)
        changeCameraButton.frame = CGRect(x: 50, y: self.height * 0.5 - 20, width: 40, height: 40)
        changeCameraButton.addTarget(self, action: #selector(changeCameraButtonClick), for: .touchUpInside)
        self.addSubview(changeCameraButton)
        
        exitButton.setImage(UIImage.init(named: "arrow_down"), for: .normal)
        exitButton.frame = CGRect(x: self.width - 50 - 40, y: self.height * 0.5 - 20, width: 40, height: 40)
        exitButton.addTarget(self, action: #selector(exitButtonClick), for: .touchUpInside)
        self.addSubview(exitButton)
    }
    
    func setupCameraButton() {
        cameraButton.frame = CGRect(x: 0, y: 0, width: WLVideoConfig.cameraButtonWidth, height: WLVideoConfig.cameraButtonWidth)
        cameraButton.center = CGPoint(x: self.width * 0.5, y: self.height * 0.5)
        cameraButton.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8823529412, blue: 0.8823529412, alpha: 1)
        cameraButton.layer.cornerRadius = cameraButton.width * 0.5
        self.addSubview(cameraButton)
        
        centerView.frame = CGRect(x: 10, y: 10, width: cameraButton.width - 20, height: cameraButton.height - 20)
        centerView.layer.cornerRadius = centerView.width * 0.5
        centerView.backgroundColor = .white
        cameraButton.addSubview(centerView)
        
        let center = cameraButton.width * 0.5
        let radius = center - 2.5
        let path = UIBezierPath(arcCenter: CGPoint(x: center, y: center), radius: radius, startAngle: .pi * -0.5, endAngle: .pi * 1.5, clockwise: true)
        
        progressLayer.frame = cameraButton.bounds
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.black.cgColor
        progressLayer.lineCap = CAShapeLayerLineCap.square
        progressLayer.path = path.cgPath
        progressLayer.lineWidth = 5
        progressLayer.strokeEnd = 0
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = cameraButton.bounds
        gradientLayer.colors = [#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1).cgColor, #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.mask = progressLayer
        cameraButton.layer.addSublayer(gradientLayer)
        
        cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGesture)))
        cameraButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:))))
    }
    
    @objc func longPressGesture(_ res: UIGestureRecognizer) {
        switch res.state {
        case .began:
            longPressBegin()
        case .changed:
            let point = res.location(in: self.cameraButton)
            if point.y <= 0 {
                self.longPressChangeBlock(Double(abs(point.y)))
            } else if point.y <= 10 {
                self.longPressChangeBlock(0)
            }
        default:
            longPressEnd()
        }
    }
    
    @objc func tapGesture() {
        self.tapBlock()
        cameraButton.isHidden = true
        changeCameraButton.isHidden = true
        exitButton.isHidden = true
    }
    
    func longPressBegin() {
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timeRecord), userInfo: nil, repeats: true)
        self.longPressBlock(.begin)
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let `self` = self else { return }
            self.cameraButton.transform = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
            self.centerView.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
        })
    }
    
    func longPressEnd() {
        guard let timer = timer else { return }
        timer.invalidate()
        self.timer = nil
        
        cameraButton.isHidden = true
        cameraButton.transform = CGAffineTransform.identity
        centerView.transform = CGAffineTransform.identity
        changeCameraButton.isHidden = true
        exitButton.isHidden = true
        progressLayer.strokeEnd = 0
        
        self.longPressBlock(.end)
    }
    
    func showCompleteAnimation() {
        self.retakeButton.isHidden = false
        self.takeButton.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.retakeButton.x = 50
            self.takeButton.x = screenWidth - self.takeButton.width - 50
        })
    }
    
    @objc func retakeButtonClick() {
        cameraButton.isHidden = false
        changeCameraButton.isHidden = false
        exitButton.isHidden = false
        retakeButton.isHidden = true
        takeButton.isHidden = true
        retakeButton.frame = cameraButton.frame
        takeButton.frame = cameraButton.frame
        
        recordTime = 0
        retakeBlock()
    }
    
    @objc func exitButtonClick() {
        self.dismissBlock()
    }
    
    @objc func takeButtonClick() {
        
    }
    
    @objc func changeCameraButtonClick() {
        self.changeCameraBlock()
    }
    
    @objc func timeRecord() {
        recordTime += 0.05
        setProgress(recordTime / videoLength)
    }
    
    func setProgress(_ p: Double) {
        if p > 1 {
            longPressEnd()
            return
        }
        progressLayer.strokeEnd = CGFloat(p)
        progressLayer.removeAllAnimations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
