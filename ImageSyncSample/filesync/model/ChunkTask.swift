import GRDB

// MARK: - 数据库模型，文件上传或下载分块
struct ChunkTask {
    var id: String //UUID, from resource UUID
    var chunk: Int //Chunk NO, 0..<chunks
    var chunkFileUrl: String //Chunk FileUrl
    var md5: String //FileUrl MD5

    var startRunningTime: Date?

    var updatedDate: Date
    var finished: Bool = false
    var error: String?
}

// MARK: - 数据映射
extension ChunkTask: Codable, FetchableRecord, MutablePersistableRecord {
    internal enum CodingKeys: String, CodingKey, ColumnExpression {
        case id = "id"
        case chunk = "chunk"
        case chunkFileUrl = "chunkFileUrl"
        case md5 = "md5"
        case startRunningTime = "startRunningTime"
        case updatedDate = "updatedDate"
        case finished = "finished"
        case error = "error"
    }
}

// MARK: - 数据访问
extension ChunkTask {
    static func getWaitingChunkTasks(_ db: Database, _ taskId: String) throws -> [ChunkTask] {
        let result = try ChunkTask
            .filter(CodingKeys.id == taskId)
            .filter(CodingKeys.startRunningTime == nil)
            .filter(CodingKeys.finished == false)
            .limit(5)
            .fetchAll(db)
        return result
    }
}

