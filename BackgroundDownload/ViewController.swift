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
        
        resetProgress()
    }

    func resetProgress() {
        percentLabel.text = "0%"
        downloadProgressView.progress = 0
    }
    
    @IBAction func startDownload(_ sender: Any) {
        resetProgress()
        
        percentLabel.text = "Started"
        let fileUrls = [ "http://www.mocky.io/v2/5a82d50e2f0000670074bba0?mocky-delay=5s"
                        ]
        let urls = fileUrls.map { return URL(string: $0) }
            .filter { $0 != nil }
            .map { $0! }
        downloadManager.startBackgroundDownloads(from: urls)
    }
}

extension ViewController: DownloadManagerDelegate {
    
    func downloading(from url: URL, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
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
    
    func downloadFailed(with error: Error) {
        DispatchQueue.main.async {
            self.percentLabel.text = "\(error)"
        }
    }

    func allDownloadsCompleted() {
    }
    
}
