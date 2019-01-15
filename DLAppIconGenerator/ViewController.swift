//
//  ViewController.swift
//  DLAppIconGenerator
//
//  Created by Dalang on 2019/1/15.
//  Copyright © 2019 Dalang. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var iconSelectButton: NSButton!
    
    @IBOutlet weak var iPhoneButton: NSButton!
    
    @IBOutlet weak var iPadButton: NSButton!
    
    @IBOutlet weak var watchButton: NSButton!
    
    @IBOutlet weak var macButton: NSButton!
    
    @IBOutlet weak var carPlayButton: NSButton!
    
    @IBOutlet weak var createButton: NSButton!
    
    @IBOutlet weak var textView: NSTextView!
    
    var inputImage: CGImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        textView.isEditable = false
    }
    
    // MARK: - Actions
    // MARK: - 选择 icon
    @IBAction func loadIcon(_ sender: Any) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        let result: NSApplication.ModalResponse = openPanel.runModal()
        var iconURL: URL?
        if #available(OSX 10.13, *) {
            if result == .OK {
                iconURL = openPanel.urls.first!
            }
        } else {
            if result == NSApplication.ModalResponse(rawValue: NSFileHandlingPanelOKButton) {
                iconURL = openPanel.urls.first!
            }
        }
        if iconURL != nil {
            if let input = AppIconGenerator.checkInputImage(url: iconURL!) {
                iconSelectButton.image = NSImage(contentsOf: iconURL!)
                inputImage = input
                addLog("请选择需要生成的 icon 类型")
            } else {
                addLog("Error: 请选择格式为 png，分辨率为 1024 * 1024 的 icon")
            }
        }
    }
    // MARK: - 选择 icon 类型
    @IBAction func selecIconType(_ sender: Any) {
        
        
    }
    
    // MARK: - 生成 icon
    @IBAction func createIcon(_ sender: Any) {
        
        let button = sender as! NSButton
        
        button.isEnabled = false
        
        addLog("开始生成 icon")
        
        // 选择图片判断
        guard let icon = inputImage else {
            addLog("Error：选择一张 1024 * 1024 png 格式的图片")
            button.isEnabled = true
            return
        }
        
        // 选择类型判断
        guard iPhoneButton.state == .on || iPadButton.state == .on || watchButton.state == .on || macButton.state == .on
            || carPlayButton.state == .on else {
                addLog("Error：请选择 icon 类型")
                button.isEnabled = true
                return
        }
        
        var iconTypes = [AppIconType]()
        if iPhoneButton.state == .on {
            iconTypes.append(AppIconType.iPhone)
        }
        if iPadButton.state == .on {
            iconTypes.append(AppIconType.iPad)
        }
        if watchButton.state == .on {
            iconTypes.append(AppIconType.appleWatch)
        }
        if macButton.state == .on {
            iconTypes.append(AppIconType.mac)
        }
        if carPlayButton.state == .on {
            iconTypes.append(AppIconType.carPlay)
        }
        
        let iconTypeStrings = iconTypes.map {
            return $0.getTypeDescription()
        }
        
        // JSON
        let jsonDecoder = JSONDecoder()
        let jsonStringData = AppIconGenerator.appIconJson().data(using: String.Encoding.utf8)!
        
        guard var appIcon = try? jsonDecoder.decode(AppIcon.self, from: jsonStringData) else {
            addLog("Error：JSON 解析失败")
            button.isEnabled = true
            return
        }
        
        appIcon.images = appIcon.images.filter {
            if iconTypes.contains(.iPhone) || iconTypes.contains(.iPad), $0.idiom == "ios-marketing" {
                return true
            }
            if iconTypes.contains(.appleWatch), $0.idiom == "watch-marketing" {
                print(2)
                return true
            }
            return iconTypeStrings.contains($0.idiom)
        }
        
        
        
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "AppIcon.appiconset"
        savePanel.message = "请选择保存路径"
        savePanel.allowsOtherFileTypes = false
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = true
        savePanel.beginSheetModal(for: NSApplication.shared.keyWindow!) { modalResponse in
            var path: String?
            if #available(OSX 10.13, *) {
                if modalResponse == .OK {
                    path = savePanel.url?.path
                }
            } else {
                if modalResponse == NSApplication.ModalResponse(rawValue: NSFileHandlingPanelOKButton) {
                    path = savePanel.url?.path
                }
            }
            if path != nil {
                AppIconGenerator.createFile(appIcon: appIcon, image: icon, atPath: path!)
                self.addLog("Success：icon 生成完成：\(path!)")
            }
        }
        button.isEnabled = true
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

extension ViewController {
    
    /// 输出日志
    ///
    /// - Parameter string: 日志
    func addLog(_ string: String) {
        
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date                 = dateFormatter.string(from: Date())
        
        let log = "[\(date)] " + string + "\n"
        
        let string = textView.string.appending(log)
        textView.string = string
        
        textView.scrollPageDown(nil)
    }
    
}

