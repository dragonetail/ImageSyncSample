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
