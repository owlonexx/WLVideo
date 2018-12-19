## WLVideo
仿照微信拍照拍视频的功能

## WLVideo有哪些功能？
* 图片视频拍摄
* 视频文件加图片水印
* 修改视频背景声音
* 自定义格式导出

## 怎样使用
```swift
  let vc = WLCameraController()
  vc.completeBlock = { url, type in
      if type == .video {
           let videoEditer = WLVideoEditor.init(videoUrl: URL.init(fileURLWithPath: url))
           videoEditer.addWaterMark(image: UIImage.init(named: "bilibili")!)
           videoEditer.addAudio(audioUrl: Bundle.main.path(forResource: "五环之歌", ofType: "mp3")!)
           videoEditer.assetReaderExport(completeHandler: { url 
           let player = WLVideoPlayer(frame: self.view.bounds)
           player.videoUrl = URL.init(fileURLWithPath: url)
           self.view.addSubview(player)
           player.play()
           })
      }
  }
  present(vc, animated: true, completion: nil)
```
