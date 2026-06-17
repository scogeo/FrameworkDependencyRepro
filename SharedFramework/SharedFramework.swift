import Foundation
internal import SharedModels
internal import Dependencies

// Normally, App Intents or other code that must live outside of SPM would live here
public struct MySharedFramework {
  @Dependency(\.myModelStore) var myModelStore
  public init() {}
}
