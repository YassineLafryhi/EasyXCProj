//
//  EasyXCProj.swift
//
//
//  Created by Yassine Lafryhi on 12/7/2024.
//

import Foundation
import PathKit
import XcodeProj

class EasyXCProj {
    private var project: XcodeProj?
    private var projectPath: String?
    private var projectName: String?
    private var mainTargetPath: String?
    private var unitTestTargetPath: String?
    private var uiTestTargetPath: String?
    private var autoSave = false

    enum ProjectType {
        case iOSApp
        case iOSFramework
        case iOSStaticLibrary
        case MacApp
        case MacCLI
    }

    init() {}

    public func createNewProject(
        projectName: String,
        projectPath: String,
        projectType: ProjectType,
        bundleIdentifier: String,
        deploymentTarget: String,
        displayName: String,
        sources: String,
        resources _: String)
    {
        self.projectPath = projectPath
        self.projectName = projectName

        switch projectType {
        case .iOSApp:
            Utils.duplicateFolder(
                atPath: NSHomeDirectory() + "/EasyXCProj/Templates/iOS/\(Constants.iOSProjectTemplateName)",
                toPath: projectPath)
            Utils.renameFolder(
                atPath: "\(projectPath)/\(Constants.iOSProjectTemplateName).xcodeproj",
                to: "\(projectName).xcodeproj")
            Utils.renameFolder(atPath: "\(projectPath)/\(Constants.iOSProjectTemplateName)", to: projectName)
            Utils.renameFile(
                atPath: "\(projectPath)/\(projectName)/\(sources)/\(Constants.iOSProjectTemplateName)App.swift",
                to: "\(projectName)App.swift")
            Utils.replaceOccurrences(
                inFilePath: "\(projectPath)/\(projectName)/\(sources)/\(projectName)App.swift",
                ofString: Constants.iOSProjectTemplateName,
                withString: projectName)
            Utils.replaceOccurrences(
                inFilePath: "\(projectPath)/\(projectName).xcodeproj/project.pbxproj",
                ofString: Constants.iOSProjectTemplateName,
                withString: projectName)
            Utils.replaceOccurrences(
                inFilePath: "\(projectPath)/\(projectName).xcodeproj/project.pbxproj",
                ofString: "16.0",
                withString: deploymentTarget)

            let projectPath = Path("\(projectPath)/\(projectName).xcodeproj")

            do {
                project = try XcodeProj(path: projectPath)

                if let teamID = Utils.fetchLastSelectedTeamID() {
                    try setSigningAccount(targetName: projectName, developmentTeam: teamID)
                }

                try updateBundleIdentifier(targetName: projectName, newIdentifier: bundleIdentifier)
                try updateDisplayName(targetName: projectName, newDisplayName: displayName)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        case .iOSFramework:
            // TODO: Implement this !
            break
        case .iOSStaticLibrary:
            // TODO: Implement this !
            break
        case .MacApp:
            // TODO: Implement this !
            break
        case .MacCLI:
            // TODO: Implement this !
            break
        }
    }

    public func loadProject(from projectPath: String) {
        do {
            projectName = Path(projectPath).lastComponentWithoutExtension
            let path = Path("\(projectPath)/\(projectName!).xcodeproj")
            let project = try XcodeProj(path: path)
            self.project = project
            self.projectPath = projectPath
            let currentDirectory = FileManager.default.currentDirectoryPath
            mainTargetPath = "\(currentDirectory)/\(projectName!)"
        } catch {
            print("Error loading project at path: \(projectPath). \(error.localizedDescription)")
        }
    }

    func addTarget(name: String, type: PBXProductType, settings: [String: Any]) throws {
        let pbxTarget = PBXNativeTarget(
            name: name,
            buildConfigurationList: nil,
            buildPhases: [],
            buildRules: [],
            dependencies: [],
            productName: name,
            productType: type)
        let buildConfigurations = settings.map { key, value in
            XCBuildConfiguration(name: key, buildSettings: value as! [String: Any])
        }
        let configList = XCConfigurationList(buildConfigurations: buildConfigurations)
        pbxTarget.buildConfigurationList = configList
        project?.pbxproj.add(object: pbxTarget)
        write()
    }

    func addFile(target: PBXTarget, filePath: String, sourceRoot: String) throws {
        let fileReference = try project?.pbxproj.fileReferences.first(where: { $0.path == filePath }) ?? createFileReference(
            path: filePath,
            sourceRoot: sourceRoot)
        let buildFile = PBXBuildFile(file: fileReference)
        project?.pbxproj.add(object: buildFile)
        if let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase {
            sourcesBuildPhase.files?.append(buildFile)
        }
        write()
    }

    private func createFileReference(path: String, sourceRoot: String) throws -> PBXFileReference {
        let sourceRootPath = Path(sourceRoot)
        let filePath = Path(path)
        let relativePath = filePath.components.dropFirst(sourceRootPath.components.count).joined(separator: "/")
        let fileReference = PBXFileReference(sourceTree: .group, name: filePath.lastComponent, path: relativePath)
        project?.pbxproj.add(object: fileReference)
        return fileReference
    }

    func setProjectBuildSettings(settings: [String: Any]) throws {
        guard let projectBuildConfigList = project?.pbxproj.rootObject?.buildConfigurationList else {
            throw NSError(
                domain: "EasyXCProjError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to find project build configuration list"])
        }
        for config in projectBuildConfigList.buildConfigurations {
            for (key, value) in settings {
                config.buildSettings[key] = value
            }
        }

        write()
    }

    func addGroupAndFiles(groupName: String, files: [String], sourceRoot: String) throws {
        let mainGroup = project?.pbxproj.rootObject?.mainGroup
        let newGroup = PBXGroup(children: [], sourceTree: .group, name: groupName)
        project?.pbxproj.add(object: newGroup)
        mainGroup!.children.append(newGroup)

        for file in files {
            let fileRef = try createFileReference(path: file, sourceRoot: sourceRoot)
            newGroup.children.append(fileRef)
        }

        write()
    }

    func addDependency(targetName: String, frameworkPath: String) throws {
        guard let target = project?.pbxproj.targets(named: targetName).first else {
            throw NSError()
        }
        let frameworkRef = project?.pbxproj.fileReferences.first(where: { $0.path == frameworkPath }) ?? PBXFileReference(
            sourceTree: .sdkRoot,
            lastKnownFileType: "wrapper.framework",
            path: frameworkPath)
        project?.pbxproj.add(object: frameworkRef)
        let buildFile = PBXBuildFile(file: frameworkRef)
        project?.pbxproj.add(object: buildFile)
        if
            let frameworksBuildPhase = target.buildPhases
                .first(where: { $0 is PBXFrameworksBuildPhase }) as? PBXFrameworksBuildPhase
        {
            frameworksBuildPhase.files?.append(buildFile)
        }

        write()
    }

    func addResources(targetName: String, resourcePaths: [String], sourceRoot: String) throws {
        guard let target = project?.pbxproj.targets(named: targetName).first else {
            throw NSError()
        }
        guard
            let resourcesBuildPhase = target.buildPhases
                .first(where: { $0 is PBXResourcesBuildPhase }) as? PBXResourcesBuildPhase else
        {
            throw NSError()
        }

        for path in resourcePaths {
            let fileRef = try createFileReference(path: path, sourceRoot: sourceRoot)
            let buildFile = PBXBuildFile(file: fileRef)
            project?.pbxproj.add(object: buildFile)
            resourcesBuildPhase.files?.append(buildFile)
        }

        write()
    }

    func addBuildScriptBeforeCompileSources(targetName: String, name: String = "Custom Script", script: String) throws {
        guard let target = project?.pbxproj.targets(named: targetName).first else {
            throw NSError()
        }
        let shellScriptBuildPhase = PBXShellScriptBuildPhase(name: name, shellScript: script)
        project?.pbxproj.add(object: shellScriptBuildPhase)
        if let index = target.buildPhases.firstIndex(where: { $0.buildPhase == .sources }) {
            target.buildPhases.insert(shellScriptBuildPhase, at: index)
        }
        write()
    }

    func getTargets() -> [String] {
        var targets: [String] = []
        let nativeTargets = project!.pbxproj.nativeTargets
        for target in nativeTargets {
            targets.append(target.name)
        }
        return targets
    }

    func updateBundleIdentifier(targetName: String, newIdentifier: String) throws {
        guard
            let target = project?.pbxproj.targets(named: targetName).first,
            let buildConfigList = target.buildConfigurationList
        else {
            return
        }

        for buildConfig in buildConfigList.buildConfigurations {
            buildConfig.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] = newIdentifier
        }
        write()
    }

    func updateDisplayName(targetName: String, newDisplayName: String) throws {
        guard
            let target = project?.pbxproj.targets(named: targetName).first,
            let buildConfigList = target.buildConfigurationList
        else {
            return
        }

        for buildConfig in buildConfigList.buildConfigurations {
            buildConfig.buildSettings["INFOPLIST_KEY_CFBundleDisplayName"] = newDisplayName
        }
        write()
    }

    func setSwiftCompilerFlags(targetName: String, flags: [String]) throws {
        guard
            let target = project?.pbxproj.targets(named: targetName).first,
            let buildConfigList = target.buildConfigurationList
        else {
            return
        }

        for buildConfig in buildConfigList.buildConfigurations {
            var existingFlags = buildConfig.buildSettings["OTHER_SWIFT_FLAGS"] as? [String] ?? []
            existingFlags.append(contentsOf: flags)
            buildConfig.buildSettings["OTHER_SWIFT_FLAGS"] = existingFlags
        }

        write()
    }

    func setSigningAccount(targetName: String, developmentTeam: String, provisioningProfileSpecifier: String? = nil) throws {
        guard
            let target = project?.pbxproj.targets(named: targetName).first,
            let buildConfigList = target.buildConfigurationList
        else {
            throw NSError(
                domain: "EasyXCProjError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Target named \(targetName) not found."])
        }

        for buildConfig in buildConfigList.buildConfigurations {
            buildConfig.buildSettings["DEVELOPMENT_TEAM"] = developmentTeam
            if let provisioningProfileSpecifier = provisioningProfileSpecifier {
                buildConfig.buildSettings["PROVISIONING_PROFILE_SPECIFIER"] = provisioningProfileSpecifier
            }
        }
        write()
    }

    func addNewSwiftFileToTarget(fileName: String, groupName: String, targetName _: String, content: String) {
        let fileRef = PBXFileReference(sourceTree: .group, name: fileName, path: "\(fileName)")
        project!.pbxproj.add(object: fileRef)
        let sg = project!.pbxproj.groups.filter {
            $0.path == groupName
        }
        .first!
        sg.children.append(fileRef)
        let buildFile = PBXBuildFile(file: fileRef)
        project!.pbxproj.add(object: buildFile)
        let target = project!.pbxproj.targets(named: projectName!).first!
        if let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase {
            sourcesBuildPhase.files?.append(buildFile)
        }
        Utils.createFileAtPath(content: content, path: "\(projectPath!)/\(projectName!)/\(groupName)/\(fileName)")
        write()
    }

    func referenceFileInProjectRoot(fileName: String) {
        let fileRef = PBXFileReference(sourceTree: .group, name: fileName, path: fileName)
        project!.pbxproj.add(object: fileRef)
        var mainGroup = project!.pbxproj.rootObject?.mainGroup
        mainGroup!.children.append(fileRef)
        write()
    }

    func addNewSwiftFileReferenceToTarget(fileName: String, groupName: String, targetName _: String) {
        // TODO: Recheck this !
        if let existingFileRef = project?.pbxproj.fileReferences.first(where: { $0.path == fileName }) {
            return
        }
        if fileName == ".DS_Store" {
            return
        }
        let fileRef = PBXFileReference(sourceTree: .group, name: fileName, path: "\(fileName)")
        project!.pbxproj.add(object: fileRef)
        let sg = project!.pbxproj.groups.filter {
            $0.path == groupName
        }
        .first!
        sg.children.append(fileRef)
        let buildFile = PBXBuildFile(file: fileRef)
        project!.pbxproj.add(object: buildFile)
        let target = project!.pbxproj.targets(named: projectName!).first!
        if let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase {
            sourcesBuildPhase.files?.append(buildFile)
        }
        write()
    }

    func createAndAddNewFileToTarget(
        fileName: String,
        inside: String? = nil,
        groupName: String,
        targetName: String,
        content: String? = nil)
    {
        if let existingFileRef = project?.pbxproj.fileReferences.first(where: { $0.path == fileName }) {
            return
        }

        let path = Path(projectPath!)
        projectName = path.lastComponentWithoutExtension
        let currentDirectory = FileManager.default.currentDirectoryPath
        var fileFullPath = "\(currentDirectory)/\(projectName!)/\(groupName)/\(fileName)"
        if let inside = inside {
            fileFullPath = "\(currentDirectory)/\(projectName!)/\(inside)/\(groupName)/\(fileName)"
        }
        Utils.createFileIfNotExist(atPath: fileFullPath, withContent: content ?? "")

        let fileRef = PBXFileReference(sourceTree: .group, name: fileName, path: "\(fileName)")
        project!.pbxproj.add(object: fileRef)
        let sg = project!.pbxproj.groups.filter {
            $0.path == groupName
        }
        .first!
        sg.children.append(fileRef)
        let buildFile = PBXBuildFile(file: fileRef)
        project!.pbxproj.add(object: buildFile)
        let target = project!.pbxproj.targets(named: targetName).first!
        if let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase {
            sourcesBuildPhase.files?.append(buildFile)
        }
        write()
    }

    func removeExistingFileFromTarget(fileName: String, inside: String? = nil, groupName: String, targetName: String) {
        let currentDirectory = FileManager.default.currentDirectoryPath
        var fileFullPath = "\(mainTargetPath)/\(groupName)/\(fileName)"
        if let inside = inside {
            fileFullPath = "\(mainTargetPath)/\(inside)/\(groupName)/\(fileName)"
        }
        Utils.deleteFileIfExists(atPath: fileFullPath)
        let fileRef = project!.pbxproj.fileReferences.filter {
            $0.path == fileName
        }
        .first!
        let sg = project!.pbxproj.groups.filter {
            $0.path == groupName
        }
        .first!
        sg.children.removeAll {
            $0 === fileRef
        }
        let target = project!.pbxproj.targets(named: targetName).first!
        let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as! PBXSourcesBuildPhase
        sourcesBuildPhase.files!.removeAll {
            $0.file === fileRef
        }
        write()
    }

    func addSPMLibrary(targetName: String, productName: String, gitUrl: String, version: String) {
        guard let project = project else {
            print("Project not loaded or initialized.")
            return
        }
        do {
            let reference = try project.pbxproj.rootObject!.addSwiftPackage(
                repositoryURL: gitUrl,
                productName: productName,
                versionRequirement: .upToNextMajorVersion(version),
                targetName: targetName)
        } catch {
            print("Error: \(error.localizedDescription)")
        }

        write()
    }

    func removeSPMLibrary(name: String) {
        guard let project = project else {
            print("Project not loaded or initialized.")
            return
        }
        for target in project.pbxproj.nativeTargets {
            let dependenciesToRemove = target.packageProductDependencies.filter {
                $0.productName == name
            }
            for dependency in dependenciesToRemove {
                if let index = target.packageProductDependencies.firstIndex(of: dependency) {
                    target.packageProductDependencies.remove(at: index)
                }
            }
        }

        // TODO: Still not complete !

        write()
    }

    func addExistingFileReferenceToTarget(filePath: String, groupName: String, targetName _: String) {
        let fileRef = PBXFileReference(sourceTree: .group, name: filePath, path: "\(filePath)")
        project!.pbxproj.add(object: fileRef)
        let sg = project!.pbxproj.groups.filter {
            $0.path == groupName
        }
        .first!
        sg.children.append(fileRef)
        let buildFile = PBXBuildFile(file: fileRef)
        project!.pbxproj.add(object: buildFile)
        let target = project!.pbxproj.targets(named: projectName!).first!
        if let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase {
            sourcesBuildPhase.files?.append(buildFile)
        }
        write()
    }

    func removeFileReferenceFromTarget(fileName: String, groupName: String, targetName _: String) {
        let fileRef = project!.pbxproj.fileReferences.filter {
            $0.path == fileName
        }
        .first!
        let sg = project!.pbxproj.groups.filter {
            $0.path == groupName
        }
        .first!
        sg.children.removeAll {
            $0 === fileRef
        }
        let target = project!.pbxproj.targets(named: projectName!).first!
        let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as! PBXSourcesBuildPhase
        sourcesBuildPhase.files!.removeAll {
            $0.file === fileRef
        }
        write()
    }

    func createNewEmptyGroupWithItsFolder(groupName: String, targetName: String) {
        let group = PBXGroup(children: [], sourceTree: .group, name: groupName)
        project!.pbxproj.add(object: group)
        let target = project!.pbxproj.targets(named: targetName).first!
        let mainGroup = project!.pbxproj.groups.filter {
            $0.path == projectName!
        }
        .first!
        mainGroup.children.append(group)
        let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as! PBXSourcesBuildPhase
        let fileRef = PBXFileReference(sourceTree: .group, name: groupName, path: "\(groupName)")
        project!.pbxproj.add(object: fileRef)
        group.children.append(fileRef)
        let buildFile = PBXBuildFile(file: fileRef)
        project!.pbxproj.add(object: buildFile)
        sourcesBuildPhase.files?.append(buildFile)
        Utils.createFolderAtPath(path: "\(mainTargetPath!)/\(groupName)")
        write()
    }

    func createNewEmptyGroupWithItsFolderInsideGroup(groupName: String, inside: String, targetName: String) {
        let group = PBXGroup(children: [], sourceTree: .group, name: groupName)

        group.path = groupName
        project!.pbxproj.add(object: group)
        let target = project!.pbxproj.targets(named: targetName).first!
        let mainGroup = project!.pbxproj.groups.filter {
            $0.path == inside
        }
        .first!
        mainGroup.children.append(group)

        /* let sourcesBuildPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as! PBXSourcesBuildPhase
         let fileRef = PBXFileReference(sourceTree: .group, name: groupName, path: "\(groupName)")
         project!.pbxproj.add(object: fileRef)
         group.children.append(fileRef)
         let buildFile = PBXBuildFile(file: fileRef)
         project!.pbxproj.add(object: buildFile)
         sourcesBuildPhase.files?.append(buildFile) */

        Utils.createFolderAtPath(path: "\(mainTargetPath!)/\(inside)/\(groupName)")
        write()
    }

    func addFileReferencesToTarget(path: String, groupName: String, targetName: String) {
        let fileManager = FileManager.default
        let sourceFolderPath = Path(path)
        let enumerator = fileManager.enumerator(atPath: sourceFolderPath.string)
        while let element = enumerator?.nextObject() as? String {
            addNewSwiftFileReferenceToTarget(fileName: element, groupName: groupName, targetName: targetName)
        }
        write()
    }

    func removeGroupWithItsFolder(groupName: String, inside: String? = nil, targetName _: String) {
        var fullPath = "\(mainTargetPath!)/\(groupName)"
        if let inside = inside {
            fullPath = "\(mainTargetPath!)/\(inside)/\(groupName)"
        }

        Utils.removeDirectoryIfExists(atPath: fullPath)

        guard let group = project!.pbxproj.groups.first(where: { $0.path == groupName }) else {
            print("Group not found: \(groupName)")
            return
        }

        if let inside = inside {
            guard let parentGroup = project!.pbxproj.groups.first(where: { $0.path == inside }) else {
                print("Parent group not found: \(inside)")
                return
            }
            parentGroup.children.removeAll { $0 === group }
        } else {
            let mainGroup = project!.pbxproj.rootObject?.mainGroup
            mainGroup?.children.removeAll { $0 === group }
        }

        write()
    }

    func updateInfoDotPlistFilePath() {
        let target = project!.pbxproj.targets(named: projectName!).first!
        let buildConfigList = target.buildConfigurationList
        for buildConfig in buildConfigList!.buildConfigurations {
            buildConfig.buildSettings["INFOPLIST_FILE"] = "\(projectName!)/Info.plist"
        }
        write()
    }

    func write() {
        try! project!.write(path: Path("\(projectPath!)/\(projectName!).xcodeproj"), override: true)
    }
}
