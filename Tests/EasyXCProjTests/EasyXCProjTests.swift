import XCTest
@testable import EasyXCProj

final class EasyXCProjTests: XCTestCase {
    func testCreateNewProject() throws {
        let excp = EasyXCProj()
        let projectPath = NSHomeDirectory() + "/Desktop/MyTestProject"

        excp.createNewProject(
            projectName: "MyTestProject",
            projectPath: projectPath,
            projectType: .iOSApp,
            bundleIdentifier: "com.company.name.MyTestProject",
            deploymentTarget: "15.0",
            displayName: "My Test Project",
            sources: "Sources",
            resources: "Resources")
    }

    func testLoadProjectAndAddSPMLibrary() throws {
        let excp = EasyXCProj()
        let projectPath = NSHomeDirectory() + "/Desktop/MyTestProject"

        excp.loadProject(from: projectPath)
        excp.addSPMLibrary(
            targetName: "MyTestProject",
            productName: "Alamofire",
            gitUrl: "https://github.com/Alamofire/Alamofire.git",
            version: "5.9.1")
    }

    func testLoadProjectAndAddNewSwiftFile() throws {
        let excp = EasyXCProj()
        let projectPath = NSHomeDirectory() + "/Desktop/MyTestProject"

        excp.loadProject(from: projectPath)

        excp.addNewSwiftFileToTarget(
            fileName: "NetworkManager.swift",
            groupName: "Sources",
            targetName: "MyTestProject",
            content: """
                import Foundation

                class NetworkManager {
                    func get(urlString: String) {
                        URLSession.shared.dataTask(with: URL(string: urlString)!) { data, _, error in
                            print(String(data: data ?? Data(), encoding: .utf8) ?? "Error: \\(error?.localizedDescription ?? "Unknown error")")
                        }.resume()
                    }
                }

                """)
    }

    func testLoadProjectAndRemoveFile() throws {
        let excp = EasyXCProj()
        let projectPath = NSHomeDirectory() + "/Desktop/MyTestProject"

        excp.loadProject(from: projectPath)

        excp.removeExistingFileFromTarget(fileName: "NetworkManager.swift", groupName: "Sources", targetName: "MyTestProject")
    }

    func testLoadProjectAndAddBuildScript() throws {
        let excp = EasyXCProj()
        let projectPath = NSHomeDirectory() + "/Desktop/MyTestProject"

        excp.loadProject(from: projectPath)

        try? excp.addBuildScriptBeforeCompileSources(targetName: "MyTestProject", name: "Lint Code With SwiftLint", script: """
            if command -v swiftlint >/dev/null 2>&1
            then
                swiftlint
            else
                echo "warning: `swiftlint` command not found - See https://github.com/realm/SwiftLint#installation for installation instructions."
            fi
            """)
    }
}
