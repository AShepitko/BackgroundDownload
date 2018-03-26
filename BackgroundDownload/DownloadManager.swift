//
//  DownloadManager.swift
//  BackgroundDownload
//
//  Created by Alexei Shepitko on 28/02/2018.
//  Copyright © 2018 Alexei Shepitko. All rights reserved.
//

import Foundation
import Alamofire

protocol DownloadManagerDelegate: class {
    func downloading(from url: URL, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    func downloaded(from url: URL, to: URL)
    func downloadFailed(with error: Error)
    func allDownloadsCompleted()
}

class DownloadManager: NSObject {

    static let backgroundSessionID = "com.distillery.BackgroundDownload.427879123"
    
    var delegate: DownloadManagerDelegate?
    
    private var resumeData: Data?
    
    private lazy var backgroundSessionManager: SessionManager = {
        let config = URLSessionConfiguration.background(withIdentifier: DownloadManager.backgroundSessionID)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        let sessionManager = SessionManager(configuration: config)
        let delegate: Alamofire.SessionDelegate = sessionManager.delegate
        
        delegate.sessionDidFinishEventsForBackgroundURLSession = { session in
            NSLog("FOOFOOFOO. DOWNLOADING EVENT. urlSessionDidFinishEvents")
            DispatchQueue.main.async {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                    let backgroundCompletionHandler =
                    appDelegate.backgroundCompletionHandler else {
                        return
                }
                backgroundCompletionHandler()
            }
        }
        return sessionManager
    }()

    func startBackgroundDownloads(from urls: [URL]) {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .background)
        for url in urls {
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent(url.lastPathComponent)
                
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            group.enter()
            backgroundSessionManager.download(url, to: destination)
                .validate(statusCode: 200..<300)
                .downloadProgress(queue: queue) { progress in
                    let totalBytesWritten = progress.completedUnitCount
                    let totalBytesExpectedToWrite = progress.totalUnitCount
                    NSLog("FOOFOOFOO. DOWNLOADING URL \(url); totalBytesWritten: \(totalBytesWritten); totalBytesExpectedToWrite: \(totalBytesExpectedToWrite); Percent: \(Int(totalBytesWritten * 100 / totalBytesExpectedToWrite))")
                    self.delegate?.downloading(from: url, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
                }
                .response { response in
                    defer {
                        group.leave()
                    }
                    if response.error == nil {
                        guard let fromUrl = response.request?.url!, let savedUrl = response.destinationURL else {
                            return
                        }
                        NSLog("FOOFOOFOO. DOWNLOADING DID FINISH. \(fromUrl). To: \(savedUrl)")
                        self.delegate?.downloaded(from: fromUrl, to: savedUrl)
                    }
                    else {
                        NSLog("FOOFOOFOO. DOWNLOADING DID FINISH. Server error: \(response.error!)")
                        self.delegate?.downloadFailed(with: response.error!)
                    }
            }
        }
        
        queue.async {
            group.wait()
            NSLog("FOOFOOFOO. ALL DOWNLOADS COMPLETED.")
            self.delegate?.allDownloadsCompleted()
        }
    }
    
}

