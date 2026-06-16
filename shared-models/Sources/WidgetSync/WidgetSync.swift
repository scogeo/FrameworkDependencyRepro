import Foundation
import Dependencies
import SharedModels

public struct WidgetSync {
  
  public func sync(model: MyModel) async {
    @Dependency(\.myModelStore) var modelStore
    
    try! await modelStore.save(model)
  }
}
