//
//  SyncManager.swift
//  ImageSyncSample
//
//  Created by dragonetail on 2019/1/1.
//  Copyright © 2019 dragonetail. All rights reserved.
//

import Foundation
import Alamofire

class SyncManager {
    static let shared = SyncManager()
    static let uploadUrl = "http://localhost:8080/superFileUpload"

    private var backgroundEventHandlers: [String: () -> ()] = [:]

    private init() {
    }

    public lazy var backgroundSessionManager: Alamofire.SessionManager = {
        let backgroundSessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.background(withIdentifier: "com.github.dragonetail.backgroundtransfer"))

        let delegate: Alamofire.SessionDelegate = backgroundSessionManager.delegate

        delegate.sessionDidFinishEventsForBackgroundURLSession = self.sessionDidFinishEventsForBackgroundURLSession
        return backgroundSessionManager
    }()


    func createUploadTask(_ filename: String, _ filePath: URL, _ size: Int, _ md5: String) -> Bool {
        do {
            let startTime = CACurrentMediaTime()
            try dbConn.write { db in
                let now = Date()
                var syncTask = SyncTask(id: UUID().uuidString, taskType: .upload, creationDate: now, startRunningTime: nil, updatedDate: now, finished: false, error: nil)
                try syncTask.save(db)

                //TODO chunks
                var uploadTask = UploadTask(id: syncTask.id, filename: filename, size: size, md5: md5, filepath: filePath.absoluteString, chunks: 1, targetUrl: SyncManager.uploadUrl, method: .post)
                try uploadTask.save(db)
            }
            log.debug("生成新的上传Task完成：\(lround((CACurrentMediaTime() - startTime) * 1000))ms")
            return true
        } catch {
            log.warning("生成新的上传Task失败：\(error)")
            return false
        }
    }

    func triggerUploadTask() -> Bool {
        var triggered = false
        do {
            try dbConn.write { db in
                let syncTasks: [SyncTask] = try SyncTask.getWaitingTasks(db)
                try syncTasks.forEach({ (_syncTask) in
                    var syncTask = _syncTask
                    syncTask.startRunningTime = Date()
                    try syncTask.update(db)
                    
                    if let uploadTask: UploadTask = try UploadTask.fetchOne(db, key: syncTask.id) {
                        SuperFileUploader.shared.upload(syncTask, uploadTask, nil, uploadTaskCallback)
                        triggered = true
                        log.debug("启动后台上传Task：\(uploadTask.id) \(uploadTask.filename)")
                    } else {
                        //TODO warning
                    }
                })
            }
        } catch {
            log.warning("启动后台上传Task失败：\(error)")
        }
        return triggered
    }

    func uploadTaskCallback(_ _syncTask: SyncTask, _ uploadTask: UploadTask, _ taskChunks: [TaskChunk]?, _ result: Bool, _error: Error?) {
        do {
            try dbConn.write { db in
                var syncTask = _syncTask
                syncTask.updatedDate = Date()
                syncTask.finished = true
                syncTask.error = nil

                try syncTask.update(db)

                //TODO chunks updates and delete
            }
            log.debug("更新Task状态完成：\(uploadTask.id) \(uploadTask.filename)")
        } catch {
            log.warning("更新Task状态失败：\(uploadTask.id) \(uploadTask.filename) \(error)")
        }
    }

}


extension SyncManager {
    func handleEventsForBackgroundURLSection(identifier: String, completionHandler: @escaping () -> ()) {
        backgroundEventHandlers[identifier] = completionHandler
    }
}

extension SyncManager {
    func sessionDidFinishEventsForBackgroundURLSession(_ session: URLSession) {
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            var triggered = false
            let preUploadTasksCount = uploadTasks.count
            if preUploadTasksCount <= 1 {
                triggered = triggered || SyncManager.shared.triggerUploadTask()
            }
            print("uploadTasks: \(preUploadTasksCount) -> \(uploadTasks.count)")

            if !triggered && dataTasks.isEmpty && uploadTasks.isEmpty && downloadTasks.isEmpty {
                let identifier = session.configuration.identifier
                if let handler = self.backgroundEventHandlers[identifier!] {
                    handler()
                    self.backgroundEventHandlers.removeValue(forKey: identifier!)
                }
            }
        }
    }
}

