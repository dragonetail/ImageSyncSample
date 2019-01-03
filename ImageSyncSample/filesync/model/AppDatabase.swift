import GRDB

/// Ref: AppDelegate.setupDatabase()
struct AppDatabase {
    static var config: Configuration {
        var config = Configuration()
        //config.readonly = true
        config.foreignKeysEnabled = true // Default is already true
        #if DEBUG
            config.trace = { print($0) } // Prints all SQL statements
        #endif
        return config
    }

    //程序启动的时候调用Queue或者Pool的打开
    static func openDatabaseQueue(_ path: String) throws -> DatabaseQueue {
        // Ref: https://github.com/groue/GRDB.swift/#database-connections
        log.info("正在启动数据库（Queue）。")
        let dbConn = try DatabaseQueue(path: path, configuration: config)
        //log.info("正在清空数据库。")
        try dbConn.erase()

        // Use DatabaseMigrator to define the database schema
        // See https://github.com/groue/GRDB.swift/#migrations
        log.info("即将执行数据库迁移。")

        try migrator.migrate(dbConn)

        return dbConn
    }

    static func openDatabasePool(_ path: String) throws -> DatabasePool {
        // Ref: https://github.com/groue/GRDB.swift/#database-connections
        log.info("正在启动数据库（Queue）。")
        let dbConn = try DatabasePool(path: path, configuration: config)
        log.info("正在清空数据库。")
        try dbConn.erase()

        // Use DatabaseMigrator to define the database schema
        // See https://github.com/groue/GRDB.swift/#migrations
        log.info("即将执行数据库迁移。")
        try migrator.migrate(dbConn)

        return dbConn
    }

    // Ref: https://github.com/groue/GRDB.swift/#migrations
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v0.1.create_tables") { db in
            log.info("即将执行数据库迁移v0.1.create_tables。")
            // Ref: https://github.com/groue/GRDB.swift#create-tables
            try db.create(table: "syncTask") { t in
                t.column("id", .text).primaryKey()
                t.column("taskType", .integer).notNull()
                t.column("creationDate", .datetime).notNull()
                t.column("state", .integer).notNull()
                t.column("chunks", .integer).notNull()
                t.column("runningChunks", .integer).notNull()
                t.column("finiahedChunks", .integer).notNull()
                t.column("startRunningTime", .datetime)
                t.column("updatedDate", .datetime).notNull()
                t.column("error", .text)
            }

            try db.create(table: "uploadTask") { t in
                t.column("id", .text).primaryKey().references("syncTask")
                t.column("filename", .text).notNull()
                t.column("size", .integer).notNull()
                t.column("md5", .text).notNull()
                t.column("fileUrl", .text).notNull()
                t.column("targetUrl", .text).notNull()
                t.column("method", .text).notNull()
            }

            try db.create(table: "chunkTask") { t in
                t.column("id", .text).references("syncTask")
                t.column("chunk", .integer).notNull()
                t.column("chunkFileUrl", .text).notNull()
                t.column("md5", .text).notNull()
                t.column("startRunningTime", .datetime)
                t.column("updatedDate", .datetime).notNull()
                t.column("finished", .boolean).notNull()
                t.column("error", .text)
                t.primaryKey(["id", "chunk"])
            }
        }

        migrator.registerMigration("fixtures") { db in
//            log.info("即将执行数据库迁移v0.1.create_tables。")
//            // Populate the players table with random data
//            for _ in 0..<8 {
//                var player = Player(id: nil, name: Player.randomName(), score: Player.randomScore())
//                try player.insert(db)
//            }
        }

        return migrator
    }
}

