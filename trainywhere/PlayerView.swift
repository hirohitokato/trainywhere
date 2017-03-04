//
//  PlayerView.swift
//  trainywhere
//
//  Created by 加藤寛人 on 2017/03/04.
//  Copyright © 2017年 Hirohito Kato. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            if let playerLayer = self.layer as? AVPlayerLayer {
                return playerLayer.player
            }
            return nil
        }
        set {
            if let playerLayer = self.layer as? AVPlayerLayer {
                playerLayer.player = newValue
            } else {
                fatalError("キャストできない?")
            }
        }
    }

    var isPlaying: Bool {
        guard let player = player else { return false }
        return player.rate != 0.0
    }
    func play() {
        guard let player = player else { return }
        player.play()
    }
    func pause() {
        guard let player = player else { return }
        player.pause()
    }
    func seek(to time: CMTime, toleranceBefore before: CMTime, toleranceAfter after: CMTime) {
        guard let player = player else {
            return }
        player.seek(to: time, toleranceBefore: before, toleranceAfter: after)
    }

}
