import XCGLogger

let appDelegate = UIApplication.shared.delegate as! AppDelegate
let log: XCGLogger = {
    #if USE_NSLOG // Set via Build Settings, under Other Swift Flags
        // Setup XCGLogger
        let log = XCGLogger.default
        log.remove(destinationWithIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier)
        log.add(destination: AppleSystemLogDestination(identifier: XCGLogger.Constants.systemLogDestinationIdentifier))
        log.logAppDetails()

    #elseif USE_OLD_SETUP_STYLE
        // This old style where we us a single setup method isn't recommended for production apps.
        // It's mostly useful for when you need a quick and dirty log, in a sample project, or unit test etc
        let log = XCGLogger.default
        let logPath: URL = appDelegate.cacheDirectory.appendingPathComponent("photosaver.log")
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath)

        // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
        // This is mostly useful when testing in the simulator, or if you have the app sending you log files remotely
        // This is also an example of how you can pull a log destination out of the logger later to alter it's setup
        if let fileDestination: FileDestination = log.destination(withIdentifier: XCGLogger.Constants.fileDestinationIdentifier) as? FileDestination {
            let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
            ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
            ansiColorLogFormatter.colorize(level: .debug, with: .black)
            ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
            ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
            ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
            ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
            fileDestination.formatters = [ansiColorLogFormatter]
        }

    #else
        // Setup XCGLogger (Advanced/Recommended Usage)
        // Create a logger object with no destinations
        let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

        // Create a destination for the system console log (via NSLog)
        let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.appleSystemLogDestination")

        // Optionally set some configuration options
        systemDestination.outputLevel = .debug
        systemDestination.showLogIdentifier = false
        systemDestination.showFunctionName = true
        systemDestination.showThreadName = true
        systemDestination.showLevel = true
        systemDestination.showFileName = true
        systemDestination.showLineNumber = true
        systemDestination.showDate = false

        // Add the destination to the logger
        log.add(destination: systemDestination)

        // Create a file log destination
        do {
            let logPath: URL = try FileManager.default
                .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("photosaver.log")
            //let logPath: URL = application.cacheDirectory.appendingPathComponent("photosaver.log")
            let autoRotatingFileDestination = AutoRotatingFileDestination(writeToFile: logPath, identifier: "advancedLogger.fileDestination", shouldAppend: true,
                                                                          attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], // Set file attributes on the log file
                                                                          maxFileSize: 1024 * 512, // 512k, not a good size for production (default is 1 megabyte)
                                                                          maxTimeInterval: 600, // 10 minute, also not good for production (default is 10 minutes)
                                                                          targetMaxLogFiles: 100) // Default is 10, max is 255
            // Optionally set some configuration options
            autoRotatingFileDestination.outputLevel = .debug
            autoRotatingFileDestination.showLogIdentifier = false
            autoRotatingFileDestination.showFunctionName = true
            autoRotatingFileDestination.showThreadName = true
            autoRotatingFileDestination.showLevel = true
            autoRotatingFileDestination.showFileName = true
            autoRotatingFileDestination.showLineNumber = true
            autoRotatingFileDestination.showDate = true

            // Process this destination in the background
            autoRotatingFileDestination.logQueue = XCGLogger.logQueue

            // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
            let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
            ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
            ansiColorLogFormatter.colorize(level: .debug, with: .black)
            ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
            ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
            ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
            ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
            autoRotatingFileDestination.formatters = [ansiColorLogFormatter]

            // Add the destination to the logger
            log.add(destination: autoRotatingFileDestination)
        } catch {
            log.error("日志文件初始化错误\(error)")
        }

        // Add basic app info, version info etc, to the start of the logs
        log.logAppDetails()

    #endif

    // You can also change the labels for each log level, most useful for alternate languages, French, German etc, but Emoji's are more fun
    //    log.levelDescriptions[.verbose] = "🗯"
    //    log.levelDescriptions[.debug] = "🔹"
    //    log.levelDescriptions[.info] = "ℹ️"
    //    log.levelDescriptions[.warning] = "⚠️"
    //    log.levelDescriptions[.error] = "‼️"
    //    log.levelDescriptions[.severe] = "💣"
    // Alternatively, you can use emoji to highlight log levels (you probably just want to use one of these methods at a time).
    let emojiLogFormatter = PrePostFixLogFormatter()
    //emojiLogFormatter.apply(prefix: "🗯 ", postfix: " ", to: .verbose)
    //emojiLogFormatter.apply(prefix: "🔹 ", postfix: " ", to: .debug)
    //emojiLogFormatter.apply(prefix: "ℹ️ ", postfix: " ", to: .info)
    emojiLogFormatter.apply(prefix: "⚠️ ", postfix: "", to: .warning)
    emojiLogFormatter.apply(prefix: "‼️ ", postfix: "", to: .error)
    emojiLogFormatter.apply(prefix: "💣 ", postfix: " ", to: .severe)
    log.formatters = [emojiLogFormatter]

    //Note: this does not work
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    dateFormatter.locale = Locale.current
    log.dateFormatter = dateFormatter

    return log
}()

//// Create custom tags for your logs
//extension Tag {
//    static let sensitive = Tag("sensitive")
//    static let ui = Tag("ui")
//    static let data = Tag("data")
//}
//
//// Create custom developers for your logs
//extension Dev {
//    static let dave = Dev("dave")
//    static let sabby = Dev("sabby")
//}
