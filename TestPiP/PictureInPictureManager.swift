//
//  PictureInPictureManager.swift
//  TestPiP
//
//  Created by Licious on 07/01/24.
//

import Foundation

import Foundation
import AVKit

class PictureInPictureManager: NSObject {
    private let pipController: AVPictureInPictureController!
//    private var pipPossibleObservation: NSKeyValueObservation?
    
    init?(playerLayer: AVPlayerLayer, isLive: Bool) {
        //Check if avPlayerLayer avaialble and Picture In Picture Mode Supported
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return nil
        }
        
        //Creates a new Picture in Picture controller.
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        super.init()
        
        //For live content, disable seek forward/backward button
        if #available(iOS 14.0, *) {
            pipController.requiresLinearPlayback = isLive
        }
        
        if #available(iOS 14.2, *) {
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        //Set Picture in Picture controller’s delegate object
        pipController.delegate = self
        
        //Observe willResignActiveNotification notification to start Picture In Picture Mode
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        
//        pipPossibleObservation = pipController.observe(\AVPictureInPictureController.isPictureInPicturePossible, options: [.initial, .old, .new]) { _, change in
//            print("[PiP] - \(change)")
//        }
    }
    
    func startPiP() {
        pipController.startPictureInPicture()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appWillResignActive(_ notification: NSNotification) {
        pipController.startPictureInPicture()
    }
}

extension PictureInPictureManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP] - Stoped.")
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP] - Started.")
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP] - Will Stop.")
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP] - Will Start.")
        //force start playback again
        pictureInPictureController.playerLayer.player?.play()
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("[PiP] - Failed to Start. Error - \(error.localizedDescription)")
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        print("[PiP] - Restore User Interface.")
        completionHandler(true)
    }
}
