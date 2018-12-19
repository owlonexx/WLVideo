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

class ViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func buttonClick(_ sender: Any) {
        let vc = WLCameraController()
        vc.completeBlock = { url, type in
            if type == .video {
                let videoEditer = WLVideoEditor.init(videoUrl: URL.init(fileURLWithPath: url))
                videoEditer.addWaterMark(image: UIImage.init(named: "bilibili")!)
                videoEditer.addAudio(audioUrl: Bundle.main.path(forResource: "五环之歌", ofType: "mp3")!)
                self.indicator.startAnimating()
                videoEditer.assetReaderExport(completeHandler: { url in
                    self.indicator.stopAnimating()
                    let player = WLVideoPlayer(frame: self.view.bounds)
                    player.videoUrl = URL.init(fileURLWithPath: url)
                    self.view.addSubview(player)
                    player.play()
                })
            }
        }
        present(vc, animated: true, completion: nil)
    }

}
