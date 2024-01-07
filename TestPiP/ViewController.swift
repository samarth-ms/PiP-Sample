//
//  ViewController.swift
//  TestPiP
//
//  Created by Licious on 04/01/24.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var auctionButtonHolderView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        UIView.animate(withDuration: 1, delay: 0.2, options: [.autoreverse, .repeat]) {
            self.auctionButtonHolderView.backgroundColor = UIColor(red: 200.0/255.0, green: 0, blue: 0, alpha: 1)
        }

    }


    @IBAction func viewAuction(_ sender: Any) {
        guard let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4") else { return }

        let streamingVC = StreamingViewController(withVideoUrl: videoURL)
        streamingVC.show()
    }
    
}

