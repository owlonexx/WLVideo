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
    let player = AVPlayer()
    var playerLayer: AVPlayerLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
        
        playerLayer = AVPlayerLayer.init(player: player)
        playerLayer.frame = layer.bounds
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPlay), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func finishPlay() {
        player.seek(to: CMTime.zero)
        player.play()
    }
    
    func play() {
        let item = AVPlayerItem.init(asset: AVURLAsset.init(url: videoUrl!))
        player.replaceCurrentItem(with: item)
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
