//
//  ViewController.swift
//  screenscanner
//
//  Created by fantast on 2023/3/19.
//

import Cocoa
import Vision
import CoreImage

class ViewController: NSViewController, NSComboBoxDelegate  {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet var result: NSTextView!
    @IBOutlet weak var scanType: NSComboBoxCell!
    
    let pasteboard = NSPasteboard.general
    var hotkey: Any?
    
    

    

        override func viewDidLoad() {
            super.viewDidLoad()
            
            
            // Do any additional setup after loading the view.
            result.string = "识别结果将展示在这里"
            result.isEditable = false
            result.isSelectable = true

            // 将文本视图添加到滚动视图中
            scrollView.documentView = result
            print("init")
            scanType.numberOfVisibleItems = 4
            scanType.removeAllItems()
            scanType.addItems(withObjectValues: ["自动","中英","纯中文（简体）","纯英文","纯中文（繁体）","韩语","日语"])
            scanType.selectItem(at: 0)
            // 注册全局事件
            let eventMask: NSEvent.EventTypeMask = [.keyDown, .flagsChanged]
            hotkey = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
                if event.keyCode == 18 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
                    // 按下了 Option + W 快捷键，调用 showAlert 函数
                    self?.handleMyScan()
                }
            }
            
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [unowned self] (event) -> NSEvent?  in
                if event.keyCode == 18 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift){
                    // 按下了 Option + W 快捷键，调用 showAlert 函数
                    self.handleMyScan()
                }
                    return nil
                }
        }
    

    
    override func viewDidAppear() {
        super.viewDidAppear()

        view.window?.makeFirstResponder(self)
        
    }

        // 监听到快捷键后调用的函数
        func handleMyScan() {
            self.scan("")
        }

        override var representedObject: Any? {
            didSet {
            // Update the view, if already loaded.
            }
        }

        deinit {
            // 在对象销毁前取消全局事件监控器的注册
            if let hotkey = hotkey {
                NSEvent.removeMonitor(hotkey)
            }
        }
    
    
    func convertCIImageToCGImage(ciImage:CIImage) -> CGImage{

            let ciContext = CIContext.init()
            let cgImage:CGImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
            return cgImage
        }
    
    
    
    
    @IBAction func scan(_ sender: Any) {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-r", "-c"]
        task.launch()
        task.waitUntilExit()
        
        //获取剪贴板
        let pasteboard = NSPasteboard.general
        // 获取剪贴板中的图片
        if let readData = pasteboard.data(forType: NSPasteboard.PasteboardType.tiff),
           let cbImage = CIImage(data: readData) {
            print(readData)
            // 执行识别文字
            let requestHandler = VNImageRequestHandler(cgImage: convertCIImageToCGImage(ciImage: cbImage))
            
            // Create a new request to recognize text.
            let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
            do{
                print(try request.supportedRecognitionLanguages())
            }catch{
                print("unable")
            }
            if(scanType.stringValue == "自动"){
                request.automaticallyDetectsLanguage = true
            }else if(scanType.stringValue == "中英"){
                request.automaticallyDetectsLanguage = false
                request.recognitionLanguages = ["zh-Hans","en-US"]
            }else if(scanType.stringValue == "纯中文（简体）"){
                request.automaticallyDetectsLanguage = false
                request.recognitionLanguages = ["zh-Hans"]
            }else if(scanType.stringValue == "纯英文"){
                request.automaticallyDetectsLanguage = false
                request.recognitionLanguages = ["en-US"]
            }else if(scanType.stringValue == "纯中文（繁体）"){
                request.automaticallyDetectsLanguage = false
                request.recognitionLanguages = ["zh-Hant"]
            }else if(scanType.stringValue == "韩语"){
                request.automaticallyDetectsLanguage = false
                request.recognitionLanguages = ["ko_KR"]
            }else if(scanType.stringValue == "日语"){
                request.automaticallyDetectsLanguage = false
                request.recognitionLanguages = ["ja-JP"]
            }else{
                request.automaticallyDetectsLanguage = true
            }
            
            
            do {
                // Perform the text-recognition request.
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform the requests: \(error).")
            }
        }
        
        func recognizeTextHandler(request: VNRequest, error: Error?) {
            guard let observations =
                    request.results as? [VNRecognizedTextObservation] else {
                return
            }
            let recognizedStrings = observations.compactMap { observation in
                // Return the string of the top VNRecognizedText instance.
                return observation.topCandidates(1).first?.string
            }
            pasteboard.clearContents()
            
            let joined = recognizedStrings.joined(separator: "\n")
            pasteboard.setString(joined, forType: .string)
            result.string = joined;
            print(recognizedStrings)
            
            // Process the recognized strings.
            //processResults(recognizedStrings)
        }
        
    }
    
}

