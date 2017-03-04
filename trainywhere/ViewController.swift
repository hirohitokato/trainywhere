//
//  ViewController.swift
//  trainywhere
//
//  Created by 加藤寛人 on 2017/03/04.
//  Copyright © 2017年 Hirohito Kato. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import ReplayKit

class ViewController: UIViewController {

    fileprivate var duration = 0.0
    fileprivate var timeObserver: Any?

    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet weak var palletteView: UIView!

    @IBOutlet weak var chooseMovieButton: UIButton!

    @IBOutlet weak var lessonButton: UIButton!

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var timerSlider: UISlider!

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        playPauseButton.setImage(UIImage(named:"play"), for: .normal)
        lessonButton.layer.cornerRadius = 4.0
        palletteView.layer.cornerRadius = 4.0

        canvasView.setup()
        initializeRecorder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if playerView.player == nil {
            setHidden(true)
        }
    }
    @IBAction func chooseMovie(_ sender: Any) {
        showPicker()
    }
}

// MARK: - Actions
extension ViewController {
    // MARK: レッスン録画イベント
    @IBAction func lessonButtonPressed(_ sender: Any) {
        isLessonRunning ? finishLesson() : startLesson()
    }

    // MARK: ムービー操作イベント
    @IBAction func playPauseTriggered(_ sender: Any) {
        guard playerView.player != nil else {
            print("\(#line): playerがnilなので無視")
            return
        }
        print("\(#function)(\(#line)): called.")

        if playerView.isPlaying {
            playerView.pause()
            playPauseButton.setImage(UIImage(named:"play"), for: .normal)
        } else {
            playerView.play()
            playPauseButton.setImage(UIImage(named:"pause"), for: .normal)
        }
    }

    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        guard playerView.player != nil else {
            print("\(#line): playerがnilなので無視")
            sender.value = 0.0
            return
        }
        playerView.pause()
        let position = duration * Double(sender.value)
        let pos_time = CMTime(seconds: position, preferredTimescale: 60)
        playerView.seek(to: pos_time,
                        toleranceBefore: CMTime(value:1, timescale:60),
                        toleranceAfter: CMTime(value:1, timescale:60))
    }

    // MARK: お絵描き関連イベント
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // パレットが隠れていいるときは何もしません
        guard !palletteView.isHidden else { return }

        if let touch = touches.first {
            let position = touch.location(in: canvasView)

            if !canvasView.frame.contains(position) {
                next?.touchesBegan(touches, with: event)
                return
            }
            canvasView.drawLine(at: position, state: .start)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // パレットが隠れていいるときは何もしません
        guard !palletteView.isHidden else { return }

        if let touch = touches.first {
            let position = touch.location(in: canvasView)
            if !canvasView.frame.contains(position) {
                next?.touchesMoved(touches, with: event)
                return
            }
            canvasView.drawLine(at: position, state: .running)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // パレットが隠れていいるときは何もしません
        guard !palletteView.isHidden else { return }

        if let touch = touches.first {
            let position = touch.location(in: canvasView)
            if !canvasView.frame.contains(position) {
                next?.touchesEnded(touches, with: event)
                return
            }
            canvasView.drawLine(at: position, state: .end)
        }
    }
    @IBAction func tappedRedPenColor(_ sender: Any) {
        canvasView.penColor = UIColor.red
    }
    @IBAction func tappedWhitePenColor(_ sender: Any) {
        canvasView.penColor = UIColor.white
    }
    @IBAction func tappedUndo(_ sender: Any) {
        canvasView.undo()
    }
    @IBAction func tappedClearCanvas(_ sender: Any) {
        canvasView.clearCanvas()
    }
}

extension ViewController {
    func setHidden(_ hidden: Bool) {
        lessonButton.isHidden = hidden
        palletteView.isHidden = hidden
        timerSlider.isHidden = hidden
        playPauseButton.isHidden = hidden
        chooseMovieButton.isHidden = !hidden
    }
}

// MARK: - 写真の選択
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    fileprivate func showPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [ kUTTypeMovie as String ]
        picker.delegate = self
        self.present(picker, animated: true) {

        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("choosed: \(info)")
        /*
         choosed: [
         "UIImagePickerControllerMediaType": public.movie,
         "UIImagePickerControllerMediaURL": file:///private/var/mobile/Containers/Data/Application/C13E7A1F-7453-4FEA-BAA3-C2708E819BDB/tmp/trim.ED5B4A19-3A55-4C16-B93F-D4ED8A0905EE.MOV,
         "UIImagePickerControllerReferenceURL": assets-library://asset/asset.mov?id=55B55CE5-1CB3-45EC-B596-9090933D6C67&ext=mov]
         */
        if let url = info[UIImagePickerControllerMediaURL] as? URL {

            if let player = playerView.player,
                let observer = timeObserver {
                print("removeTimeObserver")
                player.removeTimeObserver(observer)
                timeObserver = nil
            }

            let player = AVPlayer(url: url)
            timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30),
                                           queue: DispatchQueue.main)
            { [weak self] (t: CMTime) in
                guard let me = self, me.duration != 0.0 else { return }
                let position: Float = Float(CMTimeGetSeconds(t) / me.duration)
                me.timerSlider.value = position
            }

            // 再生時間の取得
            if let item = player.currentItem {
                duration = Double(CMTimeGetSeconds(item.asset.duration))
                print("\(duration)")
            }

            // UI更新
            timerSlider.value = 0.0
            setHidden(false)

            // 再生セットアップ
            playerView.player = player
        }
        picker.dismiss(animated: true) {
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("\(#line)")
        picker.dismiss(animated: true) {
        }
    }
}

// MARK: - レッスン録画
extension ViewController: RPScreenRecorderDelegate, RPPreviewViewControllerDelegate {
    fileprivate func initializeRecorder() {
        lessonButton.setTitle("  Start Lesson  ", for: .normal)
    }

    fileprivate var isLessonRunning: Bool {
        return RPScreenRecorder.shared().isRecording
    }
    fileprivate func startLesson() {
        lessonButton.setTitle("  Finish  ", for: .normal)
        startRecording()
    }
    fileprivate func finishLesson() {
        lessonButton.setTitle("  Start Lesson  ", for: .normal)
        playerView.pause()
        stopRecording()
    }

    private func startRecording() {
        let recorder = RPScreenRecorder.shared()
        recorder.isMicrophoneEnabled = true
        recorder.delegate = self
        recorder.startRecording { error in
            if let error = error {
                print("startRecording occurs error:\(error)")
            } else {
                print("撮影を開始")
            }
        }
    }

    private func stopRecording() {
        let recorder = RPScreenRecorder.shared()
        recorder.stopRecording { [weak self] (previewVC, error) in
            if let error = error {
                print("stopRecording occurs error:\(error)")
            }
            if let vc = previewVC {
                vc.previewControllerDelegate = self
                self?.present(vc, animated: true, completion: nil)
            }
        }
    }

    // MARK: RPScreenRecorderDelegate
    func screenRecorder(_ screenRecorder: RPScreenRecorder,
                        didStopRecordingWithError error: Error, previewViewController: RPPreviewViewController?) {

        print("\(#function)(\(#line)): called. \(screenRecorder)")
    }

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {

        print("\(#function)(\(#line)): called.")
    }

    // MARK: RPPreviewViewControllerDelegate
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {

        print("\(#function)(\(#line)): called.")
    }
    
    func previewController(_ previewController: RPPreviewViewController,
                           didFinishWithActivityTypes activityTypes: Set<String>) {
        
        print("\(#function)(\(#line)): called. activityTypes:\(activityTypes)")

        previewController.dismiss(animated: true) { [weak self] in
            if !activityTypes.isEmpty {
                let alert = UIAlertController(title: "Your lesson has been saved to Camera Roll",
                                              message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self?.playerView.player = nil
                    self?.setHidden(true)
                    self?.canvasView.clearCanvas()
                }))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
}
