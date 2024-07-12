//
//  Utils.swift
//
//
//  Created by Yassine Lafryhi on 12/7/2024.
//

import Foundation

class Utils {
    public static func fetchLastSelectedTeamID() -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        let homeDirectoryName = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
        process.arguments = [
            "defaults",
            "read",
            "/Users/\(homeDirectoryName)/Library/Preferences/com.apple.dt.Xcode.plist",
            "IDEProvisioningTeamManagerLastSelectedTeamID"
        ]
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

            return output
        } catch {
            print("Failed to fetch the last selected team ID: \(error)")
            return nil
        }
    }

    public static func createFileAtPath(content: String, path: String) {
        let fileManager = FileManager.default
        let data = content.data(using: .utf8)
        if !fileManager.fileExists(atPath: path) {
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
        } else {
            print("File already exists at path: \(path)")
        }
    }

    public static func createFolderAtPath(path: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create folder: \(error.localizedDescription)")
        }
    }

    public static func createFileAtPath(base64Content: String, path: String) {
        let fileManager = FileManager.default
        let data = Data(base64Encoded: base64Content)

        if !fileManager.fileExists(atPath: path) {
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
        } else {
            print("File already exists at path: \(path)")
        }
    }

    public static func duplicateFolder(atPath originalPath: String, toPath newPath: String) {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: originalPath) else {
            print("The folder at path \(originalPath) does not exist.")
            return
        }

        do {
            try fileManager.createDirectory(atPath: newPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create folder at path \(newPath): \(error)")
            return
        }

        do {
            let items = try fileManager.contentsOfDirectory(atPath: originalPath)
            for item in items {
                let originalItemPath = (originalPath as NSString).appendingPathComponent(item)
                let newItemPath = (newPath as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: originalItemPath, isDirectory: &isDir) {
                    if isDir.boolValue {
                        duplicateFolder(atPath: originalItemPath, toPath: newItemPath)
                    } else {
                        try fileManager.copyItem(atPath: originalItemPath, toPath: newItemPath)
                    }
                }
            }
        } catch {
            print("Failed to copy contents: \(error)")
        }
    }

    public static func replaceOccurrences(inFilePath filePath: String, ofString target: String, withString replacement: String) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath) else {
            print("The file at path \(filePath) does not exist.")
            return
        }

        do {
            let fileURL = URL(fileURLWithPath: filePath)
            var fileContents = try String(contentsOf: fileURL, encoding: .utf8)
            fileContents = fileContents.replacingOccurrences(of: target, with: replacement)
            try fileContents.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("An error occurred: \(error)")
        }
    }

    public static func renameFolder(atPath originalPath: String, to newName: String) {
        let fileManager = FileManager.default
        let originalURL = URL(fileURLWithPath: originalPath)
        let newURL = originalURL.deletingLastPathComponent().appendingPathComponent(newName)

        do {
            try fileManager.moveItem(at: originalURL, to: newURL)
        } catch {
            print("Failed to rename folder: \(error)")
        }
    }

    public static func renameFile(atPath originalPath: String, to newName: String) {
        let fileManager = FileManager.default
        let originalURL = URL(fileURLWithPath: originalPath)
        let newURL = originalURL.deletingLastPathComponent().appendingPathComponent(newName)

        do {
            try fileManager.moveItem(at: originalURL, to: newURL)
        } catch {
            print("Failed to rename file: \(error)")
        }
    }

    public static func removeDirectoryIfExists(atPath: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: atPath) {
            do {
                try fileManager.removeItem(atPath: atPath)
            } catch {
                print("Failed to delete directory at path: \(atPath)")
            }
        }
    }

    public static func deleteFileIfExists(atPath: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: atPath) {
            do {
                try fileManager.removeItem(atPath: atPath)
            } catch {
                print("Failed to delete file at path: \(atPath)")
            }
        }
    }

    public static func createFileIfNotExist(atPath filePath: String, withContent content: String) {
        let fileManager = FileManager.default
        let fileURL = URL(fileURLWithPath: filePath)

        if !fileManager.fileExists(atPath: fileURL.path) {
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to create file at \(fileURL.path): \(error)")
            }
        } else {
            print("File already exists at \(fileURL.path)")
        }
    }

    public static func replaceAllOccurrences(of: String, with: String, inside: String) -> String {
        inside.replacingOccurrences(of: of, with: with)
    }
}
