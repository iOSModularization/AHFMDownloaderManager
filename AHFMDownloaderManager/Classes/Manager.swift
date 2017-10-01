//
//  Manager.swift
//  Pods
//
//  Created by Andy Tong on 9/30/17.
//
//

import Foundation
import AHDownloader
import AHFMDataCenter

public class Manager: AHDownloaderDelegate {
    lazy var urlToID = [String: Int]()
    lazy var idToProgress = [Int: Double]()
    static let shared = Manager()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appWillResignActive(_ notification: Notification) {
        downloaderCancelAll()
    }
    
    
    public func downloaderWillStartDownload(url: String) {
        let eps = AHFMEpisode.query("audioURL", "=", url).run()
        guard eps.count > 0 else {
            return
        }
        
        let ep = eps.first!
        AHFMEpisodeInfo.write {
            if let _ = AHFMEpisodeInfo.query(byPrimaryKey: ep.id) {
                self.urlToID[url] = ep.id
            }else{
                let info = AHFMEpisodeInfo(with: ["id": ep.id])
                do {
                    try  AHFMEpisodeInfo.insert(model: info)
                    self.urlToID[url] = ep.id
                } catch let error {
                    print("AHFMDownloaderManager downloaderDidStartDownload error:\(error)")
                }
            }
        }
    }

    public func downloaderDidUpdate(url: String, progress: Double) {
        guard let id = urlToID[url] else {return}
        
        self.idToProgress[id] = progress
        
    }
    
    public func downloaderDidUpdate(url: String, fileSize: Int) {
        guard let id = urlToID[url] else {return}
        
        AHFMEpisodeInfo.write {
            do {
                try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["fileSize": fileSize])
            } catch let error {
                print("AHFMDownloaderManager downloaderDidUpdate fileSize error:\(error)")
            }
        }
    }
    public func downloaderDidUpdate(url: String, unfinishedLocalPath: String){
        guard let id = urlToID[url] else {return}
        
        AHFMEpisodeInfo.write {
            do {
                try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["unfinishedFilePath": unfinishedLocalPath])
            } catch let error {
                print("AHFMDownloaderManager downloaderDidUpdate fileSize error:\(error)")
            }
        }
    }
    public func downloaderDidFinishDownload(url:String, localFilePath: String){
        guard let id = urlToID[url] else {return}
        
        AHFMEpisodeInfo.write {
            do {
                try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["localFilePath": localFilePath])
            } catch let error {
                print("AHFMDownloaderManager downloaderDidFinishDownload fileSize error:\(error)")
            }
            self.idToProgress.removeValue(forKey: id)
            self.urlToID.removeValue(forKey: url)
        }
    }

    public func downloaderDidPausedAll() {
        AHFMEpisodeInfo.write {
            for id in self.urlToID.values {
                if let progress = self.idToProgress[id] {
                    do {
                        try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["downloadedProgress": progress])
                    } catch let error {
                        print("AHFMDownloaderManager downloaderDidUpdate progress error:\(error)")
                    }
                }
                
            }
        }
    }
    
    public func downloaderDidPaused(url: String) {
        guard let id = urlToID[url] else {return}
        
        AHFMEpisodeInfo.write {
            if let progress = self.idToProgress[id] {
                do {
                    try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["downloadedProgress": progress])
                } catch let error {
                    print("AHFMDownloaderManager downloaderDidPaused progress error:\(error)")
                }
            }
        }
    }
    
    public func downloaderCancelAll(){
        AHFMEpisodeInfo.write {
            for id in self.urlToID.values {
                do {
                    try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["localFilePath": ""])
                    try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["unfinishedFilePath": ""])
                    try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["downloadedProgress": 0.0])
                } catch let error {
                    print("AHFMDownloaderManager downloaderCancelAll error:\(error)")
                }
            }
        }
    }
    
    public func downloaderDidCancel(url:String){
        guard let id = urlToID[url] else {
            return
        }
        
        AHFMEpisodeInfo.write {
            do {
                try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["localFilePath": ""])
                try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["unfinishedFilePath": ""])
                try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["downloadedProgress": 0.0])
            } catch let error {
                print("AHFMDownloaderManager downloaderDidCancel error:\(error)")
            }
        }
        
    }
    
    public func downloaderDeletedUnfinishedTaskFiles(urls: [String]){
        AHFMEpisodeInfo.write {
            for url in urls {
                if let id = self.urlToID[url] {
                    do {
                        try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["localFilePath": ""])
                        try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["unfinishedFilePath": ""])
                        try AHFMEpisodeInfo.update(byPrimaryKey: id, forProperties: ["downloadedProgress": 0.0])
                    } catch let error {
                        print("AHFMDownloaderManager downloaderDeletedUnfinishedTaskFiles error:\(error)")
                    }
                }
            }
        }
    
    }

    public func downloaderForFileName(url: String) -> String?{
        guard let id = urlToID[url] else {
            print("downloaderForFileName failed")
            return nil
        }
        return "\(id).mp3"
    }
}
