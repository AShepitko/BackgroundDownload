//
//  ViewController.swift
//  BackgroundDownload
//
//  Created by Alexei Shepitko on 28/02/2018.
//  Copyright © 2018 Alexei Shepitko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var startButton: UIButton!
    
    let downloadManager = DownloadManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        downloadManager.delegate = self
    }

    @IBAction func startDownload(_ sender: Any) {        
        downloadManager.startBackgroundDownload(from: URL(string: "https://www.dropbox.com/s/cmbchu4fsph5x8t/despicableme-tlr5i_h720p.mov?dl=1")!)
    }
}

extension ViewController: DownloadManagerDelegate {
    
    func downloading(from url: URL, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.percentLabel.text = "\(url.lastPathComponent)... \(Int(totalBytesWritten * 100 / totalBytesExpectedToWrite))%"
            self.downloadProgressView.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        }
    }
    
    func downloaded(from url: URL, to: URL) {
        DispatchQueue.main.async {
            self.percentLabel.text = "Completed"
            self.downloadProgressView.progress = 1.0
        }
    }
    
}
