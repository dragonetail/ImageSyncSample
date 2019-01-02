//
//  FileUploader.swift
//  ImageSyncSample
//
//  Created by dragonetail on 2018/12/30.
//  Copyright © 2018 dragonetail. All rights reserved.
//

import Foundation
import Alamofire

class SuperFileUploader {
    static let shared = SuperFileUploader()
    private init() {
    }

    func upload(_ syncTask: SyncTask, _ uploadTask: UploadTask, _ taskChunks: [TaskChunk]?, _ complete: ((SyncTask, UploadTask, [TaskChunk]?, Bool, Error?) -> Void)?) {
        SyncManager.shared.backgroundSessionManager.upload(
            multipartFormData: { (multipartFormData) in
                for (key, value) in [
                    "uuid": uploadTask.id,
                    "filename": uploadTask.filename,
                    "size": String(uploadTask.size),
                    "md5": uploadTask.md5,
                    "chunks": String(uploadTask.chunks),
                    "autoMerge": "true"
                ] {
                    multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                }
                if uploadTask.chunks == 1 {
                    multipartFormData.append(URL(string: uploadTask.filepath)!, withName: "0")
                } else {
                    //TODO taskChunks
                }
            },
            usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
            to: targetUrl,
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
                            complete?(syncTask, uploadTask, taskChunks, true, response.error)
                        } else {
                            complete?(syncTask,uploadTask, taskChunks, false, response.error)
                        }
                        
                        SyncManager.shared.sessionDidFinishEventsForBackgroundURLSession(upload.session)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            })
    }


    let targetUrl = "http://localhost:8080/superFileUpload"

    func upload(_ md5File: String, _ filename: String, _ size: Int, _ filePath: URL, _ complete: @escaping ((Bool, Error?) -> Void)) {
        Alamofire.SessionManager.default.upload(
            multipartFormData: { (multipartFormData) in
                for (key, value) in [
                    "uuid": md5File,
                    "filename": filename,
                    "size": String(size),
                    "md5": md5File,
                    "chunks": "2",
                    "autoMerge": "true"
                ] {
                    multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                }

                multipartFormData.append(filePath, withName: "0")
                multipartFormData.append(filePath, withName: "1")
            },
            usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
            to: targetUrl,
            method: .post,
            headers: nil,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseString { response in
                        debugPrint(response)
                        if let result = response.result.value,
                            "true" == result.lowercased() {
                            complete(true, response.error)
                        } else {
                            complete(false, response.error)
                        }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            })
    }
}
