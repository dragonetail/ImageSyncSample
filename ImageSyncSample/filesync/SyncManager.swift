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
    static let uploadUrl = "http://192.168.218.36:8080/superFileUpload"

    private var backgroundEventHandlers: [String: () -> ()] = [:]

    private init() {
        do {
            let uploadPath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("upload")
            _ = FileUtils.delete(uploadPath.path)
            FileUtils.list()
        } catch {
            print("Failed to delete update path...")
        }
    }

    public lazy var backgroundSessionManager: Alamofire.SessionManager = {
        let backgroundSessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.background(withIdentifier: "com.github.dragonetail.backgroundtransfer"))

        let delegate: Alamofire.SessionDelegate = backgroundSessionManager.delegate

        delegate.sessionDidFinishEventsForBackgroundURLSession = self.sessionDidFinishEventsForBackgroundURLSession
        return backgroundSessionManager
    }()

    private let lock = NSLock()
    func createUploadTask(_ taskId: String, _ filename: String, _ filePath: URL, _ size: Int) -> Bool {
        do {
            let startTime = CACurrentMediaTime()
            try dbConn.write { db in
                //同步代码执行synchronized
                lock.lock(); defer { lock.unlock() }

                let now = Date()

                var syncTask = SyncTask(id: taskId, taskType: .upload, creationDate: now, state: .initial, chunks: 0, runningChunks: 0, finiahedChunks: 0, startRunningTime: nil, updatedDate: now, error: nil)
                try syncTask.save(db)

                let md5StartTime = CACurrentMediaTime()
                let md5 = try FileUtils.md5(filePath)
                print("MD5：\(lround((CACurrentMediaTime() - md5StartTime) * 1000))ms")
                var uploadTask = UploadTask(id: taskId, filename: filename, size: size, md5: md5, fileUrl: filePath.absoluteString, targetUrl: SyncManager.uploadUrl, method: .post)
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
                //同步代码执行synchronized
                lock.lock(); defer { lock.unlock() }

                let now = Date()
                let syncTasks: [SyncTask] = try SyncTask.getWaitingTasks(db)
                try syncTasks.forEach({ (syncTask) in
                    var syncTask = syncTask
                    let taskId = syncTask.id

                    guard let uploadTask: UploadTask = try UploadTask.fetchOne(db, key: taskId),
                        let fileUrl = URL(string: uploadTask.fileUrl) else {
                            log.warning("未找到任务的上传数据或数据源URL转换失败：\(taskId)")
                            return
                    }

                    if syncTask.state == .initial {
                        let destPath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("upload").appendingPathComponent(taskId)

                        let chunkFiles = try FileUtils.split(fileUrl, destPath, sourceFileSize: uploadTask.size)
                        let chunkCounts = chunkFiles.count
                        syncTask.chunks = chunkCounts

                        for chunk in 0..<chunkCounts {
                            print("Chunking...\(chunk)  \(chunkFiles[chunk])")
                            let md5StartTime = CACurrentMediaTime()
                            let md5 = try FileUtils.md5(URL(string: chunkFiles[chunk])!)
                            print("MD5：\(lround((CACurrentMediaTime() - md5StartTime) * 1000))ms")
                            var chunkTask = ChunkTask(id: taskId, chunk: chunk, chunkFileUrl: chunkFiles[chunk], md5: md5, startRunningTime: nil, updatedDate: Date(), finished: false, error: nil)
                            try chunkTask.save(db)
                        }
                    }

                    do {
                        let chunkTasks = try ChunkTask.getWaitingChunkTasks(db, taskId)

                        self.upload(syncTask, uploadTask, chunkTasks, uploadTaskCallback)
                        log.debug("启动后台上传Task：\(taskId) \(uploadTask.filename)")

                        try chunkTasks.forEach({ (chunkTask) in
                            var chunkTask = chunkTask
                            chunkTask.startRunningTime = now
                            chunkTask.updatedDate = now
                            try chunkTask.update(db)
                        })

                        syncTask.state = .preparedAndRunning
                        syncTask.runningChunks += chunkTasks.count
                        syncTask.startRunningTime = syncTask.startRunningTime ?? now
                        syncTask.updatedDate = now
                        try syncTask.update(db)

                        triggered = true
                    }
                })
            }
        } catch {
            log.warning("启动后台上传Task失败：\(error)")
        }
        return triggered
    }

    func uploadTaskCallback(_ syncTask: SyncTask, _ uploadTask: UploadTask, _ chunkTasks: [ChunkTask], _ result: Bool, error: Error?) {
        do {
            try dbConn.write { db in
                //同步代码执行synchronized
                lock.lock(); defer { lock.unlock() }

                let now = Date()

                let taskId = syncTask.id
                guard var syncTask: SyncTask = try SyncTask.fetchOne(db, key: taskId) else {
                    log.warning("未找到任务数据：\(taskId)")
                    return
                }

                if let error = error {
                    syncTask.updatedDate = now
                    syncTask.state = .failed
                    syncTask.error = error.localizedDescription
                    try syncTask.update(db)

                    try chunkTasks.forEach({ (chunkTask) in
                        var chunkTask = chunkTask
                        chunkTask.updatedDate = now
                        chunkTask.error = error.localizedDescription
                        try chunkTask.update(db)
                    })
                } else {
                    syncTask.updatedDate = now
                    syncTask.finiahedChunks += chunkTasks.count
                    if syncTask.finiahedChunks == syncTask.chunks {
                        syncTask.state = .successed
                    }
                    syncTask.error = nil
                    try syncTask.update(db)

                    try chunkTasks.forEach({ (chunkTask) in
                        var chunkTask = chunkTask
                        chunkTask.updatedDate = now
                        chunkTask.finished = true
                        chunkTask.error = nil
                        try chunkTask.update(db)
                    })
                }
            }
            log.debug("更新Task状态完成：\(uploadTask.id) \(uploadTask.filename)")
        } catch {
            log.warning("更新Task状态失败：\(uploadTask.id) \(uploadTask.filename) \(error)")
        }
    }

    func upload(_ syncTask: SyncTask, _ uploadTask: UploadTask, _ chunkTasks: [ChunkTask], _ complete: ((SyncTask, UploadTask, [ChunkTask], Bool, Error?) -> Void)?) {

        SyncManager.shared.backgroundSessionManager.upload(
            multipartFormData: { (multipartFormData) in
                for (key, value) in [
                    "uuid": uploadTask.id,
                    "filename": uploadTask.filename,
                    "size": String(uploadTask.size),
                    "md5": uploadTask.md5,
                    "chunks": String(syncTask.chunks),
                    "autoMerge": "true"
                ] {
                    multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                }

                chunkTasks.forEach({ (chunkTask) in
                    guard let chunkUrl = URL(string: chunkTask.chunkFileUrl) else {
                        log.warning("Failed to build chunk URL(\(chunkTask.chunkFileUrl)).")
                        return
                    }
                    let chunkNo = String(chunkTask.chunk)
                    multipartFormData.append(chunkUrl, withName: chunkNo, fileName: chunkTask.md5, mimeType: "application/octet-stream")
                })
            },
            usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
            to: uploadTask.targetUrl,
            method: .post,
            headers: nil,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    print("taskId: ", upload.task?.taskIdentifier ?? -1, upload.session.configuration.identifier ?? "")

                    upload.uploadProgress(closure: { (progress) in
                        //progressVal(progress.fractionCompleted) // Uploading Progress Block
                        //print("task progress: ", upload.task?.taskIdentifier ?? -1, progress.fractionCompleted)
                    })
                    upload.responseString { response in
                        debugPrint(response)
                        if let result = response.result.value,
                            "true" == result.lowercased() {
                            complete?(syncTask, uploadTask, chunkTasks, true, response.error)
                        } else {
                            complete?(syncTask, uploadTask, chunkTasks, false, response.error)
                        }

                        SyncManager.shared.sessionDidFinishEventsForBackgroundURLSession(upload.session)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            })
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

