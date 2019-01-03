import GRDB
import Alamofire

public enum TaskType: Int, Codable {
    case upload = 1
    case download = 2
}
public enum TaskState: Int, Codable {
    case initial = 1
    case preparedAndRunning = 10 // Chunk
    case failed = 20
    case successed = 21
}

// MARK: - 数据库模型，同步任务
struct SyncTask {
    var id: String //UUID, from resource UUID
    var taskType: TaskType
    var creationDate: Date
    var state: TaskState

    var chunks: Int
    var runningChunks: Int
    var finiahedChunks: Int

    var startRunningTime: Date?
    var updatedDate: Date
    var error: String?
}

// MARK: - 数据映射
extension SyncTask: Codable, FetchableRecord, MutablePersistableRecord {
    internal enum CodingKeys: String, CodingKey, ColumnExpression {
        case id = "id"
        case taskType = "taskType"
        case creationDate = "creationDate"
        case state = "state"
        case chunks = "chunks"
        case runningChunks = "runningChunks"
        case finiahedChunks = "finiahedChunks"
        case startRunningTime = "startRunningTime"
        case updatedDate = "updatedDate"
        case error = "error"
    }
}

// MARK: - 数据访问
extension SyncTask {
    static func getWaitingTasks(_ db: Database) throws -> [SyncTask] {
        let result = try SyncTask
            .filter(CodingKeys.state == TaskState.initial.rawValue || CodingKeys.state == TaskState.preparedAndRunning.rawValue)
            .order(CodingKeys.state.desc)
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

