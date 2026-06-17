import Foundation
import Dependencies
import SharedModels

public struct AppFeature {
  
  @Dependency(\.myModelStore) var modelStore
  
  public init() {}
}
