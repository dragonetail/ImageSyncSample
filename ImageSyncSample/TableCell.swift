//
//  TableCell.swift
//  ImageSyncSample
//
//  Created by dragonetail on 2018/12/30.
//  Copyright © 2018 dragonetail. All rights reserved.
//

import UIKit

class TableCell: UITableViewCell {
    static var identifier: String {
        return String(describing: TableCell.self)
    }

    var localIdentifier: String?
    var uuid: String?
    var imageFilePath: NSURL?
    var imageFileSize: Int?

}
