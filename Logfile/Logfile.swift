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

    static let maxLogSize: UInt64 = 100 // 1024*1024*100

    // MARK: - Static functions

    static func gather() -> String {
        var result: String = ""

        let urls = [Logfile.shared.makeLogfileURL(), Logfile.shared.makeOldLogfileURL()]
        urls.forEach {
            if let contents = try? String(contentsOf: $0) {
                result.append(contents)
            }
        }

        return result
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

    private func rotate() {
        guard self.size() > Logfile.maxLogSize else {
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

        fileHandle.seekToEndOfFile()
        if let data = line.data(using: .utf8) {
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

        if self.logfileHandle == nil {
            do {
                self.logfileHandle = try FileHandle(forWritingTo: url)
            } catch {
                fatalError("Can't open logfile for writing")
            }
        }
    }

    private func makeOldLogfileURL() -> URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)

        guard let documentDirectory = urls.first else {
            fatalError("Couldn't get documents directory!")
        }

        let url = documentDirectory.appendingPathComponent(self.logfileName).appendingPathExtension(self.oldLogExtension)
        return url
    }

    private func makeLogfileURL() -> URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)

        guard let documentDirectory = urls.first else {
            fatalError("Couldn't get documents directory!")
        }

        let url = documentDirectory.appendingPathComponent(self.logfileName)

        do {
            _ = try url.checkResourceIsReachable()
            return url
        } catch {
            let string = ""
            do {
                try string.write(to: url, atomically: true, encoding: .utf8)
                return url
            } catch {
                fatalError("Couldn't create logfile: \(error.localizedDescription)")
            }
        }
    }

    private init() {
        self.start()
    }

}
