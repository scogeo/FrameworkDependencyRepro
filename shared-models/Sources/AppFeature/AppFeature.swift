import Foundation
import Dependencies
import SharedModels

public struct AppFeature {
  
  public func sync(model: MyModel) async {
    @Dependency(\.myModelStore) var modelStore
    
    await modelStore.save(model)
  }
}
