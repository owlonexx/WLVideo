//
//  WLVideoPlayer.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/11.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit
import AVFoundation

class WLVideoPlayer: UIView {

    var videoUrl: URL?
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPlay), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func finishPlay() {
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    
    func play() {
        playerLayer?.removeFromSuperlayer()
        let item = AVPlayerItem.init(asset: AVURLAsset.init(url: videoUrl!))
        player = AVPlayer.init(playerItem: item)
        playerLayer = AVPlayerLayer.init(player: player)
        playerLayer?.frame = layer.bounds
        playerLayer?.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer!)
        player?.play()
    }
    
    func pause() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
