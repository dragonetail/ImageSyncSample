import GRDB
import Alamofire

public enum TaskType: Int, Codable {
    case upload = 1
    case download = 2
}


// MARK: - 数据库模型，同步任务
struct SyncTask {
    var id: String //UUID, from resource UUID
    var taskType: TaskType
    var creationDate: Date

    var startRunningTime: Date?

    var updatedDate: Date
    var finished: Bool = false
    var error: String?
}

// MARK: - 数据映射
extension SyncTask: Codable, FetchableRecord, MutablePersistableRecord {
    internal enum CodingKeys: String, CodingKey, ColumnExpression {
        case id = "id"
        case taskType = "taskType"
        case creationDate = "creationDate"
        case startRunningTime = "startRunningTime"
        case updatedDate = "updatedDate"
        case finished = "finished"
        case error = "error"
    }
}

// MARK: - 数据访问
extension SyncTask {
    static func getWaitingTasks(_ db: Database) throws -> [SyncTask] {
        let result = try SyncTask
            .filter(CodingKeys.finished == false)
            .filter(CodingKeys.startRunningTime == nil)
            .order(CodingKeys.creationDate.asc)
            .limit(3)
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


extension HTTPMethod: Codable { }

