# EasyXCProj

> A Swift library that simplifies the creation, configuration, and management of Xcode projects

![](https://img.shields.io/badge/license-MIT-brown)
![](https://img.shields.io/badge/version-0.9.0-orange)
![](https://img.shields.io/badge/Swift-5.10-blue)

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
    dependencies: [
        .package(url: "https://github.com/YassineLafryhi/EasyXCProj.git", from: "0.9.0")
    ]
```

## Usage (Other examples are in the `Tests/EasyXCProjTests` folder)

### Create new Xcode project (iOS App):

```swift
import Foundation
import EasyXCProj

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
```

### Load existing Xcode project and add an SPM library:

```swift
import Foundation
import EasyXCProj

let excp = EasyXCProj()
let projectPath = NSHomeDirectory() + "/Desktop/MyTestProject"

excp.loadProject(from: projectPath)
excp.addSPMLibrary(
            targetName: "MyTestProject",
            productName: "Alamofire",
            gitUrl: "https://github.com/Alamofire/Alamofire.git",
            version: "5.9.1")
```

### Load existing Xcode project and add a Build Script:

```swift
import Foundation
import EasyXCProj

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
```

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

[MIT License](https://choosealicense.com/licenses/mit)

