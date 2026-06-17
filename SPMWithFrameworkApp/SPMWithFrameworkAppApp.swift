import SwiftUI
import AppFeature

@main
struct SPMWithFrameworkAppApp: App {
  
  let appFeature = AppFeature()
  
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
