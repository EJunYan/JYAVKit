//
//  ViewController.swift
//  JYAVKitTest
//
//  Created by LongFu on 2017/12/29.
//  Copyright © 2017年 onelcat. All rights reserved.
//

import UIKit
import JYAVKit

class ViewController: UIViewController {

    var playView: JYBrowseVideoView?
    
    var jyImageView: JYBrowseImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textImageView()
    }
    
    func textImageView() {
        let image = #imageLiteral(resourceName: "timg.jpeg")
        jyImageView = JYBrowseImageView(frame: self.view.frame, image: image)
        self.view.addSubview(jyImageView!)
    }
    
    func textPlayVideo() {
        //        let movieURL = Bundle.main.url(forResource: "ElephantSeals", withExtension: "mov")!
        
        let movieURL = URL.init(string: "http://192.168.11.221/eS6FYbBs.mp4")!
        
        playView = JYBrowseVideoView(frame: self.view.frame, url: movieURL)
        
        self.view.addSubview((playView?.playerView!)!)
        
        self.perform(#selector(self.play), with: nil, afterDelay: 3.0)
    }
    
    @objc func play() {
        playView?.playPause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

