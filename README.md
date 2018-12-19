## WLVideo
仿照微信拍照拍视频的功能

![image](https://github.com/Weang/WLVideo/blob/master/demo.gif)

## WLVideo有哪些功能？
* 图片视频拍摄
* 双指缩放和录制视频时单指缩放
* 视频文件加图片水印
* 修改视频背景声音
* 自定义视频导出参数

## 具体使用

### WLCameraController
```swift
let vc = WLCameraController()
vc.completeBlock = { url, type in
     // url：图片视频文件路径
     // type：区分图片视频类型
}
present(vc, animated: true, completion: nil)
```

### WLVideoEditor
WLVideoEditor是封装的一个添加视频水印，更改视频背景音乐的类。
```swift
let videoEditer = WLVideoEditor.init(videoUrl: videoUrl)
// 添加水印图片
videoEditer.addWaterMark(image: UIImage.init(named: "bilibili")!)
// 替换背景音乐
videoEditer.addAudio(audioUrl: Bundle.main.path(forResource: "五环之歌", ofType: "mp3")!)
// 导出文件
videoEditer.export(progress: { (progress) in
     // progress：导出文件进度               
}, completeHandler: { (url) in
     // url：处理完成的视频路径               
})
```

### WLVideoExporter
视频导出类
系统自带的AVAssetExportSession无法自定义导出的视频参数，改用AVAssetReader和AVAssetWriter。
```swift
videoEditer.assetReaderExport(completeHandler: { _ in
})
```
