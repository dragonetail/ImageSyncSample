import GRDB

// MARK: - 数据库模型，文件上传或下载分块
struct TaskChunk {
    var id: String //UUID, from resource UUID
    var chunk: Int //Chunk NO, 0..<chunks
    var chunkFilepath: String //Chunk FilePath
    var updatedDate: Date
    var finished: Bool = false
    var error: String?
}

// MARK: - 数据映射
extension TaskChunk: Codable, FetchableRecord, MutablePersistableRecord {
    internal enum CodingKeys: String, CodingKey, ColumnExpression {
        case id = "id"
        case chunk = "chunk"
        case chunkFilepath = "chunkFilepath"
        case updatedDate = "updatedDate"
        case finished = "finished"
        case error = "error"
    }
}

// MARK: - 数据访问
extension TaskChunk {
    static func getWaitingTaskChunks(_ db: Database, _ taskId: String) throws -> [TaskChunk] {
        let result = try TaskChunk
            .filter(CodingKeys.id == taskId)
            .filter(CodingKeys.finished == false)
            .limit(10)
            .fetchAll(db)
        return result
    }
}

