//
//  DLAppIconGenerator.swift
//  DLAppIconGenerator
//
//  Created by Dalang on 2019/1/15.
//  Copyright © 2019 Dalang. All rights reserved.
//

import Foundation

struct AppIcon: Codable {
    
    var images: [AppIconImageItem]
    let info: AppIconInfo
    
    struct AppIconImageItem: Codable {
        let size: String
        let idiom: String
        let filename: String
        let scale: String
        let role: String?
        let subtype: String?
    }
    
    struct AppIconInfo: Codable {
        let version: Int
        let author: String
    }
}


struct AppIconType: OptionSet {
    let rawValue: Int
    
    static let iPhone = AppIconType(rawValue: 1 << 0)
    static let iPad = AppIconType(rawValue: 1 << 1)
    static let appleWatch = AppIconType(rawValue: 1 << 2)
    static let mac = AppIconType(rawValue: 1 << 3)
    static let carPlay = AppIconType(rawValue: 1 << 4)
    static let errorType = AppIconType(rawValue: 1 << 5)
    
    func getTypeDescription() -> String {
        switch self {
        case .iPhone:
            return "iphone"
        case .iPad:
            return "ipad"
        case .appleWatch:
            return "watch"
        case .mac:
            return "mac"
        case .carPlay:
            return "car"
        default:
            return "error"
        }
    }
    
}

struct AppIconGenerator {
    
    /// 获取 icon JSON 字符串
    ///
    /// - Returns: JSON 字符串
    static func appIconJson() -> String {
        let url = Bundle.main.url(forResource: "icon", withExtension: "json")!
        return try! String(contentsOf: url, encoding: String.Encoding.utf8)
    }
    
    /// 检查图片是否有效
    ///
    /// - Parameter url: 图片路径url
    /// - Returns: 有效返回 CGImage，无效返回 nil
    @discardableResult
    static func checkInputImage(url: URL) -> CGImage? {
        do {
            let inputData = try Data(contentsOf: url)
            let dataProvider = CGDataProvider(data: inputData as CFData)
            if let inputImage = CGImage(pngDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
                
                if inputImage.width == 1024 || inputImage.height == 1024 {
                    return inputImage
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    /// 创建appicon文件
    ///
    /// - Parameters:
    ///   - appIcon: appicon
    ///   - image: 图片
    /// - Returns: 成功或失败
    @discardableResult
    static func createFile(appIcon: AppIcon, image: CGImage, atPath path: String) -> Bool {
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(atPath: path)
            }
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            return createAppIconContentsJson(appIcon: appIcon, atPath: path) && createImages(appIcon: appIcon, image: image, atPath: path)
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    /// 创建 contentsJson
    ///
    /// - Parameter appIcon: AppIcon
    /// - Returns: 成功或失败
    @discardableResult
    static func createAppIconContentsJson(appIcon: AppIcon, atPath path: String) -> Bool {
        let encoder = JSONEncoder()
        do {
            encoder.outputFormatting = .prettyPrinted
            let appIconData = try encoder.encode(appIcon)
            if let appIconStr  = String.init(data: appIconData, encoding: .utf8) {
                let contentJsonPath = path + "/Contents.json"
                let contentJsonUrl = URL(fileURLWithPath: contentJsonPath)
                try appIconStr.write(to: contentJsonUrl, atomically: true, encoding: .utf8)
                return true
            } else {
                return false
            }
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    /// 根据appIcon生成images
    ///
    /// - Parameters:
    ///   - appIcon: appIcon
    ///   - image: 输入的图片
    ///   - path: 保存路径
    /// - Returns: 成功或失败 （有一个创建失败就失败）
    @discardableResult
    static func createImages(appIcon: AppIcon, image: CGImage, atPath path: String) -> Bool {
        for imageitem in appIcon.images {
            if let info = AppIconGenerator.getImageItemInfo(imageItem: imageitem) {
                if !AppIconGenerator.createImage(size: info.size, scale: info.scale, image: image, fileName: imageitem.filename, atPath: path) {
                    return false
                }
            } else {
                let encoder = JSONEncoder()
                do {
                    encoder.outputFormatting = .prettyPrinted
                    let imageitemData = try encoder.encode(imageitem)
                    if let imageitemString  = String(data: imageitemData, encoding: .utf8) {
                        print(imageitemString)
                        return false
                    } else {
                        return false
                    }
                } catch {
                    print(error.localizedDescription)
                    return false
                }
            }
        }
        return true
    }
    
    /// 通过imageItem获得item信息
    ///
    /// - Parameter imageItem: 传入的imageItem
    /// - Returns: 返回的信息
    static func getImageItemInfo(imageItem: AppIcon.AppIconImageItem) -> (size: CGSize, scale: CGFloat)? {
        let sizeStrs  = imageItem.size.components(separatedBy: "x")
        let scaleStrs = imageItem.scale.components(separatedBy: "x")
        if  let width = sizeStrs.first,
            let height = sizeStrs.last,
            let scale  = scaleStrs.first {
            let widthInt  = CGFloat(Double(width) ?? 0)
            let heightInt = CGFloat(Double(height) ?? 0)
            let scaleInt  = CGFloat(Double(scale) ?? 0)
            return (CGSize(width: widthInt, height: heightInt), scaleInt)
        }
        return nil
    }
    
    /// 生成单个Image
    ///
    /// - Parameters:
    ///   - size: 图片大小
    ///   - scale: 缩放倍数
    ///   - image: 图片
    ///   - fileName: 文件名
    /// - Returns: 成功或失败
    @discardableResult
    static func createImage(size: CGSize, scale: CGFloat, image: CGImage, fileName: String, atPath path: String) -> Bool {
        let width  = Int(size.width * scale)
        let height = Int(size.height * scale)
        let bitsPerComponent = image.bitsPerComponent
        let bytesPerRow = image.bytesPerRow
        let colorSpace  = CGColorSpaceCreateDeviceRGB()
        
        if let context = CGContext.init(data: nil,
                                        width: width,
                                        height: height,
                                        bitsPerComponent: bitsPerComponent,
                                        bytesPerRow: bytesPerRow,
                                        space: colorSpace,
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            context.interpolationQuality = .high
            context.draw(image, in: .init(origin: .zero, size: .init(width: width, height: height)))
            if let outputImage = context.makeImage() {
                let outputImagePath = path + "/\(fileName)"
                let outputUrl = URL(fileURLWithPath: outputImagePath) as CFURL
                let destination = CGImageDestinationCreateWithURL(outputUrl, kUTTypePNG, 1, nil)
                if let destination = destination {
                    CGImageDestinationAddImage(destination, outputImage, nil)
                    if CGImageDestinationFinalize(destination) {
                        return true
                    } else {
                        return false
                    }
                }
            } else {
                return false
            }
        }
        return false
    }
}
