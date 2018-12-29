//
//  ViewController.swift
//  ImageSyncSample
//
//  Created by dragonetail on 2018/12/29.
//  Copyright © 2018 dragonetail. All rights reserved.
//

import UIKit
import Photos
import PureLayout
import SwiftBaseBootstrap
import ImageIOSwift_F2

class ViewController: BaseViewControllerWithAutolayout {
    static let cellId: String = "UITableViewCell"

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ViewController.cellId)
        return tableView
    }()

    private lazy var fetchResult: PHFetchResult<PHAsset> = {
        let result: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        if result.count == 1,
            let smartAlbumUserLibraryCollection: PHAssetCollection = result.firstObject {

            let itemsFetchResult = PHAsset.fetchAssets(in: smartAlbumUserLibraryCollection, options: nil)

            return itemsFetchResult
        } else {
            log.severe("系统错误，发现多个用户主相册数据\(result.count)")
            fatalError("不可思议的用户相册系统，未发现用户主相册。")
        }
        return PHFetchResult<PHAsset>()
    }()
    
    private lazy var  option:UIBarButtonItem = {
        return UIBarButtonItem(title: "前台", style: .plain, target: self, action: #selector(self.optionTapped))
    }()

    override func setupAndComposeView() {
        self.title = "图片上传下载示例"
        self.view.backgroundColor = UIColor.white
        self.view.isMultipleTouchEnabled = true

        [tableView].forEach {
            view.addSubview($0)
        }
        
       
        let upload = UIBarButtonItem(title: "上传", style: .plain, target: self, action: #selector(self.uploadTapped))
        let download = UIBarButtonItem(title: "下载", style: .plain, target: self, action: #selector(self.downloadTapped))
        
        navigationItem.rightBarButtonItems = [download, upload, option]
    }

    override func setupConstraints() {
        tableView.autoPinEdgesToSuperviewEdges()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func optionTapped(){
        option.title = option.title == "前台" ? "后台": "前台"
    }
    
    @objc func uploadTapped(){
        log.info("点击了upload")
    }
    
   @objc  func downloadTapped(){
        log.info("点击了download")
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchResult.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.cellId, for: indexPath)

        let asset: PHAsset = fetchResult.object(at: indexPath.row)

        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.isSynchronous = false
        imageRequestOptions.version = .original
        PHCachingImageManager().requestImageData(for: asset, options: imageRequestOptions, resultHandler: { data, dataUTI, orientation, info in
            guard let data = data,
                let info = info else {
                    let error: String = "Failed to get image data: \(asset.localIdentifier)"
                    log.warning(error)
                    return
            }

            guard let imageSource = ImageSource(data: data) else {
                let error: String = "Failed to create ImageSource: \(asset.localIdentifier)"
                log.warning(error)
                return
            }

            let dataSize: Int = data.count
            let dataSizeStr: String = ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .file)
            let fileUrl = info["PHImageFileURLKey"] as? NSURL
            let filename: String = fileUrl?.lastPathComponent ?? "-"


            cell.imageView?.image = imageSource.image()
            cell.textLabel?.text = "\(indexPath.row): \(filename) (\(dataSizeStr))"
        })
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.info("点击了\(indexPath.row)")
    }
}


