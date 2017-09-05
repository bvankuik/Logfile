//
//  Logfile.swift
//  Logfile
//
//  Created by Bart van Kuik on 31/08/2017.
//  Copyright © 2017 DutchVirtual. All rights reserved.
//

import Foundation


class Logfile {

    static let shared = Logfile()

    private var logfileURL: URL?
    private var logfileHandle: FileHandle?
    private let logfileName = "logfile.txt"
    private let oldLogExtension = "old"
    private let dateFormatter = DateFormatter()

    static var maxLogSize: UInt64 = Logfile.defaultMaxLogSize
    static let defaultMaxLogSize: UInt64 = 1024*1024*100
    static var includeDate: Bool = false

    // MARK: - Static functions

    static func gather() -> String {
        let contents = Logfile.shared.gather()
        return contents
    }

    static func urlForSharing() -> URL {
        let url = Logfile.shared.urlForSharing()
        return url
    }

    static func write(line: String) {
        if line.hasSuffix("\n") {
            Logfile.shared.write(line: line)
        } else {
            Logfile.shared.write(line: line + "\n")
        }
        Logfile.shared.rotate()
    }

    static func clear() {
        Logfile.shared.clear()
    }

    static func size() -> UInt64 {
        return Logfile.shared.size()
    }

    // MARK: - Private functions

    private func urlForSharing() -> URL {
        let tmpURL = Logfile.shared.pathForTemporaryFile(with: "Logfile")

        let contents = self.gather()
        do {
            try contents.write(to: tmpURL, atomically: true, encoding: .utf8)
        } catch {
            print("Warning: issue creating file [\(tmpURL)], error: \(error.localizedDescription)")
        }

        return tmpURL
    }


    private func pathForTemporaryFile(with prefix: String) -> URL {
        let uuid = UUID().uuidString
        let pathComponent = "\(prefix)-\(uuid)"
        var tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        tempPath.appendPathComponent(pathComponent)
        return tempPath
    }

    private func gather() -> String {
        var result: String = ""

        let urls = [self.makeLogfileURL(), self.makeOldLogfileURL()]
        urls.forEach {
            if let contents = try? String(contentsOf: $0) {
                result.append(contents)
            }
        }

        return result
    }

    private func rotate() {
        guard self.size() >= Logfile.maxLogSize else {
            return
        }

        guard let fileHandle = self.logfileHandle, let url = self.logfileURL else {
            fatalError("No filehandle for logfile")
        }

        fileHandle.closeFile()

        self.removeOldLogfile()

        let oldURL = self.makeOldLogfileURL()
        do {
            try FileManager.default.moveItem(at: url, to: oldURL)
        } catch {
            print("Warning: issue moving file [\(url)] to [\(oldURL)], error:")
            print(error.localizedDescription)
        }

        self.logfileURL = nil
        self.logfileHandle = nil
        self.start()
    }

    private func removeOldLogfile() {
        let oldURL = self.makeOldLogfileURL()
        do {
            let exists = try oldURL.checkResourceIsReachable()
            if exists {
                try FileManager.default.removeItem(at: oldURL)
            }
        } catch {
            print("Warning: issue when deleting old log file [\(oldURL)]:")
            print(error.localizedDescription)
        }
    }

    private func size() -> UInt64 {
        guard let url = self.logfileURL else {
            fatalError("No URL for logfile")
        }

        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = attr[FileAttributeKey.size] as! UInt64
            return size
        } catch {
            fatalError("Couldn't get size of logfile: \(error.localizedDescription)")
        }
    }

    private func write(line: String) {
        guard let fileHandle = self.logfileHandle else {
            fatalError("First open logfile for writing")
        }

        let lineToWrite: String
        if Logfile.includeDate {
            let dateString = self.dateFormatter.string(from: Date())
            lineToWrite = "\(dateString) \(line)"
        } else {
            lineToWrite = line
        }

        fileHandle.seekToEndOfFile()
        if let data = lineToWrite.data(using: .utf8) {
            fileHandle.write(data)
            fileHandle.synchronizeFile()
        }
    }

    private func clear() {
        guard let fileHandle = self.logfileHandle else {
            fatalError("No logfileHandle")
        }

        fileHandle.truncateFile(atOffset: 0)

        self.removeOldLogfile()
    }

    private func start() {
        self.logfileURL = self.makeLogfileURL()

        guard let url = self.logfileURL else {
            fatalError("Couldn't get URL for logfile")
        }

        self.touch()

        if self.logfileHandle == nil {
            do {
                self.logfileHandle = try FileHandle(forWritingTo: url)
            } catch {
                fatalError("Can't open logfile for writing")
            }
        }
    }

    private func makeOldLogfileURL() -> URL {
        return self.makeURL(filename: self.logfileName, fileExtension: self.oldLogExtension)
    }

    private func makeLogfileURL() -> URL {
        return self.makeURL(filename: self.logfileName, fileExtension: nil)
    }

    private func touch() {
        let url = makeLogfileURL()

        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
    }

    private func makeURL(filename: String, fileExtension: String?) -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        guard let directory = urls.first else {
            fatalError("Couldn't get documents directory!")
        }

        if let ext = fileExtension {
            return directory.appendingPathComponent(filename).appendingPathExtension(ext)
        } else {
            return directory.appendingPathComponent(filename)
        }
    }

    private init() {
        self.start()
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    }

}
