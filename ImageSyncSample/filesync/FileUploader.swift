//
//  FileUploader.swift
//  ImageSyncSample
//
//  Created by dragonetail on 2018/12/30.
//  Copyright © 2018 dragonetail. All rights reserved.
//

import Foundation
import Alamofire

class FileUploader {
    let baseUrl = "http://localhost:8080/chunk"

    func checkAndUpload(_ filePath: URL) {
        let filename = filePath.lastPathComponent
        let md5File: String = "ABCDEF123456"
        self.checkFile(md5File) { (result: Bool, error: Error?) in
            guard error == nil else {
                print(error!)
                return
            }
            guard result == false else {
                print("File existed...")
                return
            }

            self.checkChunk(md5File, 0) { (result: Bool, error: Error?) in
                guard error == nil else {
                    print(error!)
                    return
                }
                if result {
                    print("Chunk existed...")
                }

                self.upload(md5File, 0, filePath) { (result: Bool, error: Error?) in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    guard result == true else {
                        print("File upload failed...")
                        return
                    }

                    self.merge(md5File, 1, filename) { (result: Bool, error: Error?) in
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        guard result == true else {
                            print("File merge failed...")
                            return
                        }

                        print("File update and merge successed...")
                    }
                }
            }
        }
    }

    func checkFile(_ md5File: String, _ complete: @escaping ((Bool, Error?) -> Void)) {
        Alamofire.request(
            baseUrl + "/checkFile",
            method: .post,
            parameters: ["md5File": md5File],
            encoding: URLEncoding.default)
            .validate()
            .responseString { (response) in
                debugPrint(response)

                if let result = response.result.value,
                    "true" == result.lowercased() {
                    complete(true, response.error)
                } else {
                    complete(false, response.error)
                }
        }
    }

    func checkChunk(_ md5File: String, _ chunk: Int, _ complete: @escaping ((Bool, Error?) -> Void)) {
        Alamofire.request(
            baseUrl + "/checkChunk",
            method: .post,
            parameters: ["md5File": md5File, "chunk": String(chunk)],
            encoding: URLEncoding.default)
            .validate()
            .responseString { (response) in
                debugPrint(response)

                if let result = response.result.value,
                    "true" == result.lowercased() {
                    complete(true, response.error)
                } else {
                    complete(false, response.error)
                }
        }
    }

    func upload(_ md5File: String, _ chunk: Int, _ filePath: URL, _ complete: @escaping ((Bool, Error?) -> Void)) {
        Alamofire.upload(
            multipartFormData: { (multipartFormData) in
                for (key, value) in ["md5File": md5File,
                                     "chunk": String(chunk)] {
                    multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                }

                multipartFormData.append(filePath, withName: "file")
            },
            //usingThreshold: MultipartUpload.encodingMemoryThreshold,
            to: baseUrl + "/upload",
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

    func merge(_ md5File: String, _ chunks: Int, _ filename: String, _ complete: @escaping ((Bool, Error?) -> Void)) {
        Alamofire.request(
            baseUrl + "/merge",
            method: .post,
            parameters: ["md5File": md5File,
                         "chunks": String(chunks),
                         "name": filename],
            encoding: URLEncoding.default)
            .validate()
            .responseString { (response) in
                debugPrint(response)

                if let result = response.result.value,
                    "true" == result.lowercased() {
                    complete(true, response.error)
                } else {
                    complete(false, response.error)
                }
        }
    }

}
