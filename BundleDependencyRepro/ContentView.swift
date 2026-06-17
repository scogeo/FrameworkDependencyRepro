import SwiftUI
import Dependencies
import SharedModels

struct ContentView: View {
  
  @Dependency(\.myModelStore) var myModelStore
  
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
