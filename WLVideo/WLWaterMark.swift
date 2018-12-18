//
//  WLWaterMark.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/14.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit
import AVFoundation

class WLWaterMark: NSObject {
    
    static func addVideo(url: URL, complete: @escaping (String) -> ()) {
        
        let avAsset = AVAsset(url: url)
        let assetTime = avAsset.duration
        
        guard let avAssetVideoTrack = avAsset.tracks(withMediaType: .video).first,
            let avAssetAudioTrack = avAsset.tracks(withMediaType: .audio).first else {
                complete(url.absoluteString)
                return
        }
        
        let videoTransform = avAssetVideoTrack.preferredTransform
        let naturalSize = avAssetVideoTrack.naturalSize
        let videoSize = self.transformSize(naturalSize, to: videoTransform)
        let videoRotate = self.translatedBy(naturalSize, transform: videoTransform)
        
        let avMutableComposition = AVMutableComposition()
        let video = avMutableComposition.addMutableTrack(withMediaType: .video,
                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
        try? video?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: assetTime),
                                    of: avAssetVideoTrack,
                                    at: .zero)
        
        let audio = avMutableComposition.addMutableTrack(withMediaType: .audio,
                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
        try? audio?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: assetTime),
                                    of: avAssetAudioTrack,
                                    at: .zero)

        let parentLayer = CALayer()
        parentLayer.backgroundColor = UIColor.clear.cgColor
        parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: avAssetVideoTrack)
        layerInstruction.setTransform(videoRotate, at: .zero)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: assetTime)
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = .init(value: 1, timescale: 30)
        videoComposition.animationTool = .init(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        videoComposition.instructions = [instruction]

        parentLayer.addSublayer(videoLayer)
        let animatedTitleLayer = createLayer(videoSize: videoSize)
        parentLayer.addSublayer(animatedTitleLayer)
        
        let savePath = createFileUrl("MOV")
        let avAssetExportSession = AVAssetExportSession.init(asset: avMutableComposition, presetName: AVAssetExportPresetHighestQuality)
        avAssetExportSession?.videoComposition = videoComposition
        avAssetExportSession?.outputURL = .init(fileURLWithPath: savePath)
        avAssetExportSession?.outputFileType = .mov
        avAssetExportSession?.shouldOptimizeForNetworkUse = true
        
        avAssetExportSession?.exportAsynchronously(completionHandler: {
            if avAssetExportSession?.status == .completed {
                DispatchQueue.main.async {
                    complete(savePath)
                }
            }
        })
    }
    
    static func createFileUrl(_ type: String) -> String {
        let formate = DateFormatter()
        formate.dateFormat = "yyyyMMddHHmmss"
        let fileName = formate.string(from: Date()) + "." + type
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let filePath = path! + "/" + fileName
        return filePath
    }
    
    static func createLayer(videoSize: CGSize) -> CALayer {
        let animatedTitleLayer = CALayer()
        animatedTitleLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        animatedTitleLayer.backgroundColor = UIColor.clear.cgColor
        
        let imageView = UIImageView(frame: CGRect(x: 30, y: videoSize.height - 150, width: 270, height: 120))
        imageView.image = UIImage.init(named: "bilibili")
        animatedTitleLayer.addSublayer(imageView.layer)
        
        return animatedTitleLayer
    }
    
    static func transformSize(_ naturalSize: CGSize, to transform: CGAffineTransform) -> CGSize {
        let videoSize: CGSize
        if transform.a * transform.d + transform.b * transform.c == -1 {
            videoSize = CGSize(width: min(naturalSize.width, naturalSize.height),
                               height: max(naturalSize.width, naturalSize.height))
        } else {
            videoSize = CGSize(width: max(naturalSize.width, naturalSize.height),
                               height: min(naturalSize.width, naturalSize.height))
        }
        return videoSize
    }
    
    static func translatedBy(_ naturalSize: CGSize, transform: CGAffineTransform) -> CGAffineTransform {
        var x: CGFloat = 0
        var y: CGFloat = 0
        if transform.a + transform.b == -1 {
            x = -naturalSize.width
        }
        if transform.c + transform.d == -1 {
            y = -naturalSize.height
        }
        return transform.translatedBy(x: x, y: y)
    }
    
}
