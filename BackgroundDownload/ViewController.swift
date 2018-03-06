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
        let fileUrls = [ "https://www.dropbox.com/s/cmbchu4fsph5x8t/despicableme-tlr5i_h720p.mov?dl=1",
                         "https://www.dropbox.com/s/nf8o6v8a1lupegq/despicableme2-tlr22_h720p.mov?dl=1"
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
        //
    }
    
    func allDownloadsCompleted() {
        DispatchQueue.main.async {
            self.percentLabel.text = "Completed"
            self.downloadProgressView.progress = 1.0
        }
    }
    
}
