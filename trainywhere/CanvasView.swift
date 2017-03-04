//
//  CanvasView.swift
//  trainywhere
//
//  Created by 加藤寛人 on 2017/03/04.
//  Copyright © 2017年 Hirohito Kato. All rights reserved.
//

import UIKit

class CanvasView: UIImageView {

    enum EventState {
        case start, running, end
    }
    struct LinePath {
        var path: UIBezierPath
        let color: UIColor
        let width: CGFloat
    }

    var penColor: UIColor = UIColor.red

    fileprivate var currentPath: LinePath?
    fileprivate var lastDrawImage: UIImage?
    fileprivate var undoStack = [LinePath]()

    // MARK: - お絵描き(http://dev.classmethod.jp/smartphone/iphone/ios-touch-drawing/)
    func setup() {
        clearCanvas()
    }

    func clearCanvas() {
        lastDrawImage = nil
        image = nil
        undoStack.removeAll()
    }

    func drawLine(at position: CGPoint, state: EventState) {

        switch state {
        case .start:
            // パスを初期化します。
            currentPath = LinePath(path: UIBezierPath(), color: penColor, width: 4.0)
            currentPath?.path.lineCapStyle = .round
            currentPath?.path.lineWidth = 4.0
            currentPath?.path.move(to: position)
        case .running:
            guard let currentPath = currentPath else { return }

            // パスにポイントを追加して線を描画します
            currentPath.path.addLine(to: position)
            drawLine(path: currentPath, continueDrawing: true)
        case .end:
            guard let currentPath = currentPath else { return }
            // パスにポイントを追加して線を描画します
            currentPath.path.addLine(to: position)
            drawLine(path: currentPath)

            // undo用にパスを保持して現在のパスをリセットします
            undoStack.append(currentPath)
            self.currentPath = nil
        }
    }

    func undo() {
        // undoスタックからパスを取り出します
        guard let _ = undoStack.last else { return }
        undoStack.removeLast()

        // いったん画面をクリアします
        lastDrawImage = nil;
        self.image = nil

        // 画面にパスを描画します
        for path in undoStack {
            drawLine(path: path)
        }
    }

    private func drawLine(path: LinePath, continueDrawing: Bool = false) {
        // 非表示の描画領域を生成します
        UIGraphicsBeginImageContext(self.frame.size)

        // 描画領域に、前回までに描画した画像を、描画します
        lastDrawImage?.draw(at: CGPoint.zero)

        // 色をセットします
        path.color.setStroke()

        // 線を引きます
        path.path.stroke()

        // 描画した画像をcanvasにセットして、画面に表示します
        self.image = UIGraphicsGetImageFromCurrentImageContext()

        // 描画を終了します
        UIGraphicsEndImageContext()

        // 区切りが良ければ最後に書いた画面を更新します
        if !continueDrawing {
            lastDrawImage = self.image
        }
    }

}
