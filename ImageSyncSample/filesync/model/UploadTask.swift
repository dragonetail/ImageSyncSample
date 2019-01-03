import GRDB
import Alamofire


// MARK: - 数据库模型，文件上传任务
struct UploadTask {
    var id: String //UUID, equal to Resource UUID
    var filename: String //filename
    var size: Int
    var md5: String //Resource MD5
    var fileUrl: String //Original fileUrl
    var targetUrl: String
    var method: HTTPMethod
}

// MARK: - 数据映射
extension UploadTask: Codable, FetchableRecord, MutablePersistableRecord {
    internal enum CodingKeys: String, CodingKey, ColumnExpression {
        case id = "id"
        case filename = "filename"
        case size = "size"
        case md5 = "md5"
        case fileUrl = "fileUrl"
        case targetUrl = "targetUrl"
        case method = "method"
    }
}

// MARK: - 数据访问
extension UploadTask {
    static func getWaitingTasks(_ db: Database) throws -> [UploadTask] {
        let result = try UploadTask
            //.filter(CodingKeys.isSuccessful == nil)
            //.order(CodingKeys.creationDate.asc)
            .limit(10)
            .fetchAll(db)
        return result
    }
    
    //
    //    static func deleteBy(_ db: Database, assetId: String) throws -> Int {
    //        let counts = try ImageModel
    //            .filter(CodingKeys.assetId == assetId)
    //            .deleteAll(db)
    //
    //        return counts
    //    }
    //
    //    static func getBy(_ db: Database, assetId: String) throws -> ImageModel? {
    //        let imageModel = try ImageModel
    //            .filter(CodingKeys.assetId == assetId)
    //            .fetchOne(db)
    //
    //        return imageModel
    //    }
    
    
    //.fetchOne(db, key: 1)
    
    
    //    Player.including(required: Player.team)
    //    Player.order(nameColumn)..reversed().filter(emailColumn != nil)
    //    static func getById(_ db: Database, id: String) throws -> ImageModel? {
    //        let imageModel = try ImageModel
    //            .filter(CodingKeys.id == id)
    //            .fetchOne(db)
    //
    //        return imageModel
    //    }
}


