//
//  FileChunkUtils.swift
//  ImageSyncSample
//
//  Created by dragonetail on 2019/1/3.
//  Copyright © 2019 dragonetail. All rights reserved.
//

import Foundation
import CryptoSwift

struct FileUtils {
    static let fileManager = FileManager.default

    static func exists(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }

//    static func size(_ path: String) throws -> Int {
//        let fileAttributes = try fileManager.attributesOfFileSystem(forPath: path)
//        if let fileSize = fileAttributes[FileAttributeKey.size] as? UInt64 {
//            return Int(fileSize)
//        } else {
//            throw NSError(domain: "Failed to get a size attribute from path: \(path).", code: -1, userInfo: nil)
//        }
//    }

    static func isWritableFile(_ path: String) -> Bool {
        return fileManager.isWritableFile(atPath: path)
    }

    static func createDirectory(_ path: URL) throws {
        try fileManager.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
    }

    static func delete(_ path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    static func list() {
        if let enumeratorAtPath: NSEnumerator = fileManager.enumerator(atPath: NSHomeDirectory()) {
            print("enumeratorAtPath: ")
            enumeratorAtPath.allObjects.forEach { (path) in
                print("  \(path)")
            }
        }
    }


    //Ref: https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/PerformanceTips/PerformanceTips.html#//apple_ref/doc/uid/TP40010672-CH7-SW1
    static var bufferSize: Int = 256 * 1024  // 256KB
    static var chunkSizeTimes: Int = 1 // 32
    static var chunkSize: Int = bufferSize * chunkSizeTimes // 8MB
    static func split(_ source: URL, _ destPath: URL, sizeTimes: Int, sourceFileSize: Int) throws -> [String] {
        return try split(source, destPath, bufferSize * sizeTimes, sourceFileSize: sourceFileSize)
    }

    static func split(_ source: URL, _ destPath: URL, _ chunkSize: Int = chunkSize, sourceFileSize: Int) throws -> [String] { // 8MB
        var chunkFiles = [String]()

        if sourceFileSize <= chunkSize { //不用分块
            chunkFiles.append(source.absoluteString)
            return chunkFiles
        }

        guard let sourceInputStream = InputStream(url: source) else {
            throw NSError(domain: "Failed to open source file(\(source)).", code: -1, userInfo: nil)
        }
        defer {
            sourceInputStream.close()
        }
        sourceInputStream.open()

        if FileUtils.exists(destPath.path) {
            _ = FileUtils.delete(destPath.path)
        }
        try FileUtils.createDirectory(destPath)
        fileManager.createFile(atPath: destPath.path + "/testFile", contents: "Hello".data(using: .utf8), attributes: nil)

        var chunk = 0
        var finished = false
        while !finished {
            let chunkFile = destPath.appendingPathComponent("\(chunk)")
            guard let destOutputStream = OutputStream(toFileAtPath: chunkFile.path, append: false) else {
                //guard let destOutputStream = OutputStream(url: chunkFile, append: false) else {
                throw NSError(domain: "Failed to create chunk file(\(chunkFile)).", code: -1, userInfo: nil)
            }
            defer {
                destOutputStream.close()
                do {
                    print("destOutputStream.close()...*** \(FileUtils.exists(chunkFile.path))   .... \(try md5(chunkFile))")
                } catch {
                    print("@@@@@@@@@@@@@@@")
                }
            }
            destOutputStream.open()

            finished = try FileUtils.copyFile(sourceInputStream, destOutputStream, chunkSize)

            chunkFiles.append(chunkFile.absoluteString)
            chunk += 1
        }
        return chunkFiles
    }

    static func merge(_ sourcePath: String, _ dest: String, _ chunks: Int) throws {
        guard let destOutputStream = OutputStream(toFileAtPath: dest, append: false) else {
            throw NSError(domain: "Failed to create dest file(\(dest)).", code: -1, userInfo: nil)
        }
        defer {
            destOutputStream.close()
        }

        for chunk in 0 ..< chunks {
            let chunkFile = sourcePath + "/\(chunk)"
            guard let sourceInputStream = InputStream(fileAtPath: chunkFile) else {
                throw NSError(domain: "Failed to open chunk file(\(chunkFile)).", code: -1, userInfo: nil)
            }

            let _ = try FileUtils.copyFile(sourceInputStream, destOutputStream)
            sourceInputStream.close()
        }
    }

    static func copyFile(_ source: InputStream, _ dest: OutputStream, _ size: Int = Int.max) throws -> Bool {
        var counts = 0
        var buff: [UInt8] = [UInt8](repeating: 0x0, count: bufferSize)
        var dataLen = bufferSize
        while counts < size {
            dataLen = source.read(&buff, maxLength: bufferSize)
            counts += dataLen

            if dataLen > 0 {
                let written = dest.write(&buff, maxLength: dataLen)
                if dataLen != written {
                    throw NSError(domain: "Failed to write file \(dataLen) -> \(written).", code: -1, userInfo: nil)
                }
            }

            if dataLen < bufferSize {
                return true //End of source file
            }
        }
        return false
    }

    static func md5(_ source: URL) throws -> String {
        //guard let sourceInputStream = InputStream(fileAtPath: source.path) else {
        guard let sourceInputStream = InputStream(url: source) else {
            throw NSError(domain: "Failed to open source file(\(source)).", code: -1, userInfo: nil)
        }
        defer {
            sourceInputStream.close()
        }
        sourceInputStream.open()

        var digest = MD5()
        var buff: [UInt8] = [UInt8](repeating: 0x0, count: bufferSize)
        var dataLen = bufferSize
        while dataLen == bufferSize {
            dataLen = sourceInputStream.read(&buff, maxLength: bufferSize)

            if(dataLen <= 0) {
                break
            } else if dataLen == bufferSize {
                let _ = try digest.update(withBytes: buff)
            } else {
                let _ = try digest.update(withBytes: buff.prefix(dataLen))
            }
        }
        let result = try digest.finish()
        let md5 = result.toHexString().uppercased()
        print("md5: \(md5)")

        return md5
    }
}
