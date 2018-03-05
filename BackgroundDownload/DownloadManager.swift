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
}

class DownloadManager: NSObject {

    static let backgroundSessionID = "com.distillery.BackgroundDownload.427879123"
    
    var delegate: DownloadManagerDelegate?
    
    private var resumeData: Data?
    
    private lazy var backgroundSessionManager: SessionManager = {
        let config = URLSessionConfiguration.background(withIdentifier: DownloadManager.backgroundSessionID)
        config.isDiscretionary = true
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
    
    var backgroundCompletionHandler: (() -> Void)? {
        get {
            return backgroundSessionManager.backgroundCompletionHandler
        }
        set {
            backgroundSessionManager.backgroundCompletionHandler = newValue
        }
    }

    func startBackgroundDownload(from url: URL) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(url.lastPathComponent)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

//        let request: DownloadRequest
//        if let resumeData = resumeData {
//            request = backgroundSessionManager.download(resumingWith: resumeData)
//        } else {
//            request = backgroundSessionManager.download(url, to: destination)
//        }
//        request
        
        backgroundSessionManager.download(url, to: destination)
            .downloadProgress(queue: DispatchQueue.main) { progress in
                let totalBytesWritten = progress.completedUnitCount
                let totalBytesExpectedToWrite = progress.totalUnitCount
                NSLog("FOOFOOFOO. DOWNLOADING URL \(url); totalBytesWritten: \(totalBytesWritten); totalBytesExpectedToWrite: \(totalBytesExpectedToWrite); Percent: \(Int(totalBytesWritten * 100 / totalBytesExpectedToWrite))")
                self.delegate?.downloading(from: url, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            }
            .response { response in
                if response.error == nil, let fromUrl = response.request?.url, let savedUrl = response.destinationURL {
                    NSLog("FOOFOOFOO. DOWNLOADING DID FINISH. \(fromUrl)")
                    self.delegate?.downloaded(from: fromUrl, to: savedUrl)
                }
                else {
                    NSLog("FOOFOOFOO. DOWNLOADING DID FINISH. Server error")
                }
            }
        
    }
    
}
/*
extension DownloadManager: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        NSLog("FOOFOOFOO. DOWNLOADING DID FINISH. \(location)")
        guard let fromUrl = downloadTask.originalRequest?.url else {
            return
        }
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
                NSLog("FOOFOOFOO. DOWNLOADING DID FINISH. Server error")
                return
        }
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let savedURL = documentsURL.appendingPathComponent(
                fromUrl.lastPathComponent)
            try FileManager.default.moveItem(at: location, to: savedURL)
            self.delegate?.downloaded(from: fromUrl, to: savedURL)
            NSLog("FOOFOOFOO. FILE SAVED. \(savedURL)")
        } catch {
            NSLog("FOOFOOFOO. MOVE FILE ERROR. \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard let fromUrl = downloadTask.originalRequest?.url else {
            return
        }
        NSLog("FOOFOOFOO. RESUME URL \(fromUrl); didResumeAtOffset: \(fileOffset); expectedTotalBytes: \(expectedTotalBytes); Percent: \(Int(fileOffset * 100 / expectedTotalBytes))")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let fromUrl = downloadTask.originalRequest?.url else {
            return
        }
        NSLog("FOOFOOFOO. DOWNLOADING URL \(fromUrl); totalBytesWritten: \(totalBytesWritten); totalBytesExpectedToWrite: \(totalBytesExpectedToWrite); Percent: \(Int(totalBytesWritten * 100 / totalBytesExpectedToWrite))")
        self.delegate?.downloading(from: fromUrl, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        NSLog("FOOFOOFOO. DOWNLOADING COMPLETES. urlSessionDidFinishEvents")
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let backgroundCompletionHandler =
                appDelegate.backgroundCompletionHandler else {
                    return
            }
            backgroundCompletionHandler()
        }
    }
    
}
*/
