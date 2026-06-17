import SwiftUI
import AppFeature

@main
struct SPMOnlyAppApp: App {
  
    let appFeature = AppFeature()
  
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
