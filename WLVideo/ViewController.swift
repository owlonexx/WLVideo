//
//  ViewController.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/11.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

let screenHeight = UIScreen.main.bounds.size.height
let screenWidth = UIScreen.main.bounds.size.width

class ViewController: UIViewController, UITableViewDelegate {

    @IBAction func buttonClick(_ sender: Any) {

//        let videoEditer = WLVideoEditor.init(videoUrl: URL.init(fileURLWithPath: Bundle.main.path(forResource: "1", ofType: "mp4")!))
//        videoEditer.addWaterMark()
//        videoEditer.addAudio()
//        videoEditer.rotatoTo(CGAffineTransform.init(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: 0))
//        let item = AVPlayerItem.init(asset: videoEditer.composition)
//        let videoComposition = videoEditer.videoComposition
//        videoComposition.animationTool = nil
//        item.videoComposition = videoComposition
//        let player = AVPlayer.init(playerItem: item)
//        let playerLayer = AVPlayerLayer.init(player: player)
//        playerLayer.frame = self.view.bounds
//        playerLayer.videoGravity = .resizeAspect
//        self.view.layer.addSublayer(playerLayer)
//        player.play()

        
        let vc = WLCameraController()
        vc.completeBlock = { url, type in
            if type == .video {
                let videoEditer = WLVideoEditor.init(videoUrl: URL.init(fileURLWithPath: url))
                videoEditer.addWaterMark()
                videoEditer.addAudio()
                videoEditer.export(completeHandler: { (completeUrl) in
                    let videoPlayer = WLVideoPlayer.init(frame: self.view.bounds)
                    videoPlayer.videoUrl = URL.init(fileURLWithPath: completeUrl)
                    self.view.addSubview(videoPlayer)
                    videoPlayer.play()
                })
            }
        }
        present(vc, animated: true, completion: nil)
    }

}
