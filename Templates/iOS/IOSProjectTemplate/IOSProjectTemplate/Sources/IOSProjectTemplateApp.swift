import SwiftUI

@main
struct IOSProjectTemplateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
