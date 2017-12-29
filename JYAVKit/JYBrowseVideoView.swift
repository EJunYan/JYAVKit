//
//  JYBrowseVideoView.swift
//  JYAVKit
//
//  Created by LongFu on 2017/12/27.
//  Copyright © 2017年 onelcat. All rights reserved.
//

import UIKit
import AVFoundation


public protocol JYBrowseVideoDelegate {
     func playVideo(error: String)
}

/*
 KVO context used to differentiate KVO callbacks for this class versus other
 classes in its class hierarchy.
 */
private var playerKVOContext = 0

open class JYBrowseVideoView: NSObject {
    
    // MARK: Properties
    

    // Attempt load and test these asset keys before playing.
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]
    
    @objc let player = AVPlayer()
    
    open var delegate: JYBrowseVideoDelegate?
    
    open var playerView: PlayerView?
    
    open var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, 1)
            player.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    open var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    open var rate: Float {
        get {
            return player.rate
        }
        
        set {
            player.rate = newValue
        }
    }
    
    open var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else { return }
            
            asynchronouslyLoadURLAsset(newAsset)
        }
    }
    
    private var playerLayer: AVPlayerLayer? {
        return playerView?.playerLayer
    }
    

    
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverToken: Any?
    
    private var playerItem: AVPlayerItem? = nil {
        didSet {
            /*
             If needed, configure player item here before associating it with a player.
             (example: adding outputs, setting text style rules, selecting media options)
             */
            player.replaceCurrentItem(with: self.playerItem)
        }
    }
    
    // MARK: - Asset Loading
    
    func asynchronouslyLoadURLAsset(_ newAsset: AVURLAsset) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.loadValuesAsynchronously(forKeys: JYBrowseVideoView.assetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                /*
                 `self.asset` has already changed! No point continuing because
                 another `newAsset` will come along in a moment.
                 */
                guard newAsset == self.asset else { return }
                
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in JYBrowseVideoView.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
//                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
//                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
//                        self.handleErrorWithMessage(message, error: error)
                        
                        if let delegate = self.delegate {
                            delegate.playVideo(error: "Can't use this AVAsset because one of it's keys failed to load")
                        }
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.isPlayable || newAsset.hasProtectedContent {
//                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
//                    self.handleErrorWithMessage(message)
                    
                    if let delegate = self.delegate {
                        delegate.playVideo(error: "Can't use this AVAsset because it isn't playable or has protected content")
                    }
                    return
                }
                
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                self.playerItem = AVPlayerItem(asset: newAsset)
            }
        }
    }
    
    open func rewind() {
        // Rewind no faster than -2.0.
        rate = max(player.rate - 2.0, -2.0)
    }
    
    open func fastForward() {
        // Fast forward no faster than 2.0.
        rate = min(player.rate + 2.0, 2.0)
    }
    
    open func seek(time: Double) {
        currentTime = time
    }
    
    open func playPause() {
        if player.rate != 1.0 {
            // Not playing forward, so play.
            if currentTime == duration {
                // At end, so got back to begining.
                currentTime = 0.0
            }
            
            player.play()
        }
        else {
            // Playing, so pause.
            player.pause()
        }
    }
    
    /// 视频持续时间 单位:s
    open var durationTime: Float = 0.0
    
    /// 播放时间
    open var currentPlayTime: Float = 0.0
    
    /// 是否有效视频
    open var hasValidDuration: Bool = false
    
    open func play(url: URL) {

        asset = AVURLAsset(url: url, options: nil)
        
        // Make sure we don't have a strong reference cycle by only capturing self as weak.
        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            self.currentPlayTime = Float(timeElapsed)
            
//            self.timeSlider.value = Float(timeElapsed)
//            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
        }
    }
    
    public init(frame: CGRect, url: URL) {
        super.init()
        playerView = PlayerView(frame: frame)
        playerView?.backgroundColor = UIColor.black
        playerView?.frame = frame

        
        addObserver(self, forKeyPath: #keyPath(JYBrowseVideoView.player.currentItem.duration), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(JYBrowseVideoView.player.rate), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(JYBrowseVideoView.player.currentItem.status), options: [.new, .initial], context: &playerKVOContext)
        
        playerView?.playerLayer.player = player
        

        play(url: url)
    }
    
    
    // MARK: - KVO Observation
    
    // Update our UI when player or `player.currentItem` changes.
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &playerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(JYBrowseVideoView.player.currentItem.duration) {
            // Update timeSlider and enable/disable controls when duration > 0.0
            
            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            }
            else {
                newDuration = kCMTimeZero
            }
            
            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            self.durationTime = Float(newDurationSeconds)
            
            self.currentPlayTime = currentTime
            
            self.hasValidDuration = hasValidDuration
            
            
//            timeSlider.maximumValue = Float(newDurationSeconds)
//
//            timeSlider.value = currentTime
//
//            rewindButton.isEnabled = hasValidDuration
//
//            playPauseButton.isEnabled = hasValidDuration
//
//            fastForwardButton.isEnabled = hasValidDuration
//
//            timeSlider.isEnabled = hasValidDuration
//
//            startTimeLabel.isEnabled = hasValidDuration
//            startTimeLabel.text = createTimeString(time: currentTime)
//
//            durationLabel.isEnabled = hasValidDuration
//            durationLabel.text = createTimeString(time: Float(newDurationSeconds))
        }
        else if keyPath == #keyPath(JYBrowseVideoView.player.rate) {
            // Update `playPauseButton` image.
            
            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
            
            // 播放到最后按钮切换
            if newRate == 1.0 {
                // 可以暂停
            } else {
                // 可以播放
            }
//            let buttonImageName = newRate == 1.0 ? "PauseButton" : "PlayButton"
            
//            let buttonImage = UIImage(named: buttonImageName)
            
//            playPauseButton.setImage(buttonImage, for: UIControlState())
        }
        else if keyPath == #keyPath(JYBrowseVideoView.player.currentItem.status) {
            // Display an error if status becomes `.Failed`.
            
            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            let newStatus: AVPlayerItemStatus
            
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
            }
            else {
                newStatus = .unknown
            }
            
            if newStatus == .failed {
//                handleErrorWithMessage(player.currentItem?.error?.localizedDescription, error:player.currentItem?.error)
                if let delegate = self.delegate {
                    delegate.playVideo(error: (player.currentItem?.error?.localizedDescription)!)
                }
            }
        }
    }
    
    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     [#keyPath(JYBrowseVideoView.player.currentItem.duration)],
            "rate":         [#keyPath(JYBrowseVideoView.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    deinit {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        player.pause()
        
        removeObserver(self, forKeyPath: #keyPath(JYBrowseVideoView.player.currentItem.duration), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(JYBrowseVideoView.player.rate), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(JYBrowseVideoView.player.currentItem.status), context: &playerKVOContext)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Convenience
    
    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    open func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }

}

