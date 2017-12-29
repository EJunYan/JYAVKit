//
//  JYBrowseImageView.swift
//  JYAVKit
//
//  Created by LongFu on 2017/12/27.
//  Copyright © 2017年 onelcat. All rights reserved.
//

import UIKit

// MARK: - 支持放大缩小
// TODO: - 后期加上网络图片加载
// TODO: - 网络图片下载进度条

open class JYBrowseImageView: UIScrollView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    private var imageView: UIImageView?
    
    public init(frame: CGRect, image: UIImage) {
        
        super.init(frame: frame)
        self.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        self.delegate = self
        
        let minScale = imageScale(size: image.size)
        
        if imageView == nil {
            // TODO: imgae自适应 进行缩放
            
            
            let frame = CGRect.init(origin: CGPoint.zero, size: image.size)
            imageView = UIImageView(frame: frame)
            self.addSubview(imageView!)
        }
        
        self.imageView?.image = image
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        
        self.minimumZoomScale = minScale
        self.maximumZoomScale = 3
        
        self.setZoomScale(minScale, animated: true)
        
    }
    
    func imageScale(size: CGSize)-> CGFloat {
        if size.width > self.frame.width {
            let scale = self.frame.width / size.width
            return scale
        }
        return 1.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.imageView = nil
    }
    
}

extension JYBrowseImageView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ?
            (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
        
        self.imageView?.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        
    }
    
    
}

