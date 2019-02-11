//
//  UIImage+Ext.swift
//  ExtensionTool
//
//  Created by 张崇超 on 2018/7/10.
//  Copyright © 2018年 ZCC. All rights reserved.
//

import UIKit
import CoreFoundation

extension UIImage {

    /// 根据颜色创建一个图片
    ///
    /// - Parameter color: 颜色
    /// - Returns: 图片
    static func k_imageWithColor(_ color: UIColor) -> UIImage? {
        
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        
        let ref = UIGraphicsGetCurrentContext()
        ref?.setFillColor(color.cgColor)
        ref?.fill(rect)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return img
    }
    
    /// 重新布局图片
    ///
    /// - Parameter newSize: 新尺寸
    /// - Returns: 新图片
    func k_resizeImage(with newSize: CGSize) -> UIImage {
        
        let newWidth = newSize.width
        let newHeight = newSize.height
        
        let width = self.size.width
        let height = self.size.height
        
        if (width != newWidth) || (height != newHeight) {
            
            UIGraphicsBeginImageContextWithOptions(newSize, true, UIScreen.main.scale)
            self.draw(in: CGRect(x: 0.0, y: 0.0, width: newWidth, height: newHeight))
            
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resized ?? self
        }
        return self
    }
    
    //MARK: 改变图片尺寸
    /// 改变图片尺寸
    ///
    /// - Parameter size: 修改的尺寸
    /// - Returns: 新图片
    func k_cropImageWith(newSize: CGSize) -> UIImage {
        
        let scale = self.size.width / self.size.height
        var rect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        if scale > newSize.width / newSize.height {
            
            rect.size.width = self.size.height * newSize.width / newSize.height
            rect.origin.x = (self.size.width - rect.size.width) / 2.0
            rect.size.height = self.size.height

        } else {
            
            rect.origin.y = (self.size.height - self.size.width / newSize.width * newSize.height) / 2.0
            rect.size.width = self.size.width
            rect.size.height = self.size.width / newSize.width * newSize.height
        }
        let imgRef = self.cgImage!.cropping(to: rect)
        let newImg = UIImage.init(cgImage: imgRef!)
        
        return newImg
    }
    
    //MARK: 裁剪圆形为圆形
    /// 裁剪为圆形图片
    ///
    /// - Parameters:
    ///   - backColor: 裁剪为圆形 空白区域的背景颜色 默认白色
    ///   - borderColor: 边框颜色
    ///   - borderWidth: 边框宽度
    /// - Returns: 新图片
    func k_circleImage(backColor: UIColor? = UIColor.white, borderColor: UIColor? = nil, borderWidth: CGFloat? = 0.0) -> UIImage {
        
        // 圆形图片
        let imgW: CGFloat = self.size.width
        let imgH: CGFloat = self.size.height
        let imgWH: CGFloat = min(imgW, imgH)
        let squareImg = self.k_cropImageWith(newSize: CGSize.init(width: imgWH, height: imgWH))
        // 圆形框
        let rect = CGRect(origin: CGPoint(), size: squareImg.size)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, true, UIScreen.main.scale)
        // 填充
        (backColor ?? UIColor.white).setFill()
        UIRectFill(rect)
        
        // 形状
        let circlePath = UIBezierPath.init(ovalIn: rect)
        circlePath.addClip()
        
        squareImg.draw(in: rect)
        
        // 是否有边框
        if let borderColor = borderColor {
            
            borderColor.setStroke()
            circlePath.lineWidth = borderWidth ?? 1.0
            circlePath.stroke()
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result ?? self
    }
    
    //MARK: 压缩图片大小
    /// 压缩图片大小
    ///
    /// - Parameters:
    ///   - imgSize: 图片大小 默认原图尺寸
    ///   - kbSize: 压缩大小
    /// - Returns: 数据流
    func k_pressImgSize(imgSize: CGSize? = nil, kbSize: CGFloat = 60.0) -> Data? {
        
        // kb大小
        var maxSize = kbSize
        if (maxSize <= 0.0) {
            maxSize = 1024.0;
        }
        // 宽高
        var newImg = self
        var newSize: CGSize!
        if let imgSize = imgSize {
            
            if self.size.width <= imgSize.width {
                newSize = self.size
            } else {
                newImg = self.k_cropImageWith(newSize: imgSize)
                newSize = CGSize.init(width: newImg.size.width, height: newImg.size.height)
            }
            
        } else {
            
            // 等比例缩放
            let wantImgWidth: CGFloat = 414.0
            if self.size.width <= wantImgWidth {
                newSize = self.size
            } else {
                let scale: CGFloat = self.size.width / self.size.height
                let wantImgHeight: CGFloat = wantImgWidth / scale
                newImg = self.k_cropImageWith(newSize: CGSize(width: wantImgWidth, height: wantImgHeight))
                newSize = CGSize.init(width: newImg.size.width, height: newImg.size.height)
            }
        }
        UIGraphicsBeginImageContext(newSize)
        newImg.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let newImage = newImage, let imgData = newImage.jpegData(compressionQuality: 0.9) {
            
            var imageData: Data = imgData
            var sizeOriginKB : CGFloat = CGFloat(imageData.count) / 1024.0;
            //调整大小
            var resizeRate: CGFloat = 0.6;
            
            while (sizeOriginKB > maxSize && resizeRate > 0.0) {
                
                if let newData = newImage.jpegData(compressionQuality: resizeRate) {
                    
                    imageData = newData
                    sizeOriginKB = CGFloat(imageData.count) / 1024.0
                    resizeRate -= 0.02
                }
            }
            debugPrint("图片压缩大小为:\(sizeOriginKB)")
            return imageData
        }
        return nil
    }
    
}