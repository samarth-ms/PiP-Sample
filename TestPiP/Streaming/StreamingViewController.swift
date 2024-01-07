//
//  StreamingViewController.swift
//  TestPiP
//
//  Created by Licious on 07/01/24.
//

import UIKit
import AVFoundation
import AVKit

class StreamingViewController: UIViewController, AVPictureInPictureControllerDelegate {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var playPauseImage: UIImageView!
    @IBOutlet weak var bidButton: UIButton!
    @IBOutlet weak var pipButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var videoURL: URL
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var pictureInPictureManager: PictureInPictureManager?
    private static var strongRef: StreamingViewController?
    private var timeControlStatusObservation: NSKeyValueObservation?

    // MARK: - Lifecycle
    
    init(withVideoUrl videoUrl: URL) {
        self.videoURL = videoUrl
        super.init(nibName: "StreamingViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.clipsToBounds = true
        // Do any additional setup after loading the view.
        setupVideo()
        closeButton.layer.shadowColor = UIColor.black.cgColor
        closeButton.layer.shadowOffset = .zero
        closeButton.layer.shadowRadius = 4
        closeButton.layer.shadowOpacity = 0.8
        pipButton.layer.shadowColor = UIColor.black.cgColor
        pipButton.layer.shadowOffset = .zero
        pipButton.layer.shadowRadius = 4
        pipButton.layer.shadowOpacity = 0.8
        playPauseImage.layer.shadowColor = UIColor.black.cgColor
        playPauseImage.layer.shadowOffset = .zero
        playPauseImage.layer.shadowRadius = 12
        playPauseImage.layer.shadowOpacity = 0.6
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Update playerLayer frame
        playerLayer.frame = playerView.bounds
    }
    
    func show() {
        guard Self.strongRef == nil else {
            Self.strongRef?.stopPiP()
            return
        }
        guard let mainWindow = UIApplication.shared.windows.first else { return }
        var initialFrame = mainWindow.frame
        initialFrame.origin.y = initialFrame.height
        self.view.frame = initialFrame
        
        mainWindow.addSubview(self.view)
        
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.2) {
            self.view.frame = mainWindow.frame
        }
        
        Self.strongRef = self
    }
    
    func remove() {
        guard let mainWindow = UIApplication.shared.windows.first else { return }
        player.pause()
        
        var finalFrame = view.frame
        finalFrame.origin.y = mainWindow.frame.height
                
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.2, options: .curveEaseOut) {
            self.view.frame = finalFrame
        } completion: { success in
            self.view.removeFromSuperview()
            Self.strongRef = nil
        }
    }
    
    // MARK: - Setup
    
    func setupVideo() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch  {
            debugPrint("Error in setting audio session category. Error -\(error.localizedDescription)")
        }
        
        //Create AVPlayer and AVPlayerLayer
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        
        checkPlayerTimeControlStatus()

        //Create PictureInPictureManager with playerLayer to enable PiP Mode
        pictureInPictureManager = PictureInPictureManager(playerLayer: playerLayer, isLive: false)
        
        //Added playerLayer to playerView
        playerView.layer.addSublayer(playerLayer)
        
        player.play()
    }
    
    // MARK: - User actions
    
    @IBAction func closeAction(_ sender: Any) {
        remove()
    }
    
    @IBAction func togglePiP(_ sender: UIButton) {
        if sender.isSelected {
            stopPiP()
        } else {
            startPiP()
        }
    }
    
    @IBAction func togglePlayPauseAction(_ sender: Any) {
        UIView.animate(withDuration: 0.2) {
            self.playPauseImage.alpha = 1
        }
        if player.rate == 0 {
            player.play()
            playPauseImage.image = UIImage(systemName: "pause.fill")
            UIView.animate(withDuration: 1, delay: 1, options: .curveEaseIn) {
                self.playPauseImage.alpha = 0.0
            }
        } else {
            player.pause()
            playPauseImage.image = UIImage(systemName: "play.fill")
        }

    }
    
    @IBAction func doubleTapAction(_ sender: Any) {
        if playerLayer.videoGravity == .resizeAspectFill {
            playerLayer.videoGravity = .resizeAspect
        } else {
            playerLayer.videoGravity = .resizeAspectFill
        }
    }
    
    // MARK: - Picture In Picture

    
    func startPiP() {
        guard let mainWindow = UIApplication.shared.windows.first else { return }
        let windowFrame = mainWindow.frame
        var newFrame = self.view.frame
        pipButton.isSelected = true
        
        let scaleFactor: CGFloat = 0.4
        newFrame = windowFrame.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        newFrame.origin.x = windowFrame.width - newFrame.width - 12
        newFrame.origin.y = windowFrame.height - newFrame.height - mainWindow.safeAreaInsets.bottom - 12
        
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.2) {
            self.view.frame = newFrame
            self.view.cornerRadius = 16
            self.bidButton.alpha = 0
            self.bidButton.isEnabled = false
            self.view.layoutIfNeeded()
        }
    }
    
    func stopPiP() {
        guard let mainWindow = UIApplication.shared.windows.first else { return }
        let windowFrame = mainWindow.frame
        pipButton.isSelected = false
        
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.2) {
            self.view.frame = windowFrame
            self.view.cornerRadius = 0
            self.bidButton.alpha = 1
            self.bidButton.isEnabled = true
            self.view.layoutIfNeeded()
        }
    }

    private func checkPlayerTimeControlStatus() {
        timeControlStatusObservation = player.observe(\AVPlayer.timeControlStatus, options: [.new]) { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else {
                return
            }
            
            if newValue == .playing {
                self.activityIndicator.stopAnimating()
            } else {
                self.activityIndicator.startAnimating()
            }
        }
    }
}
