
import Dependencies
import DependenciesMacros
public import Foundation

public struct MyModel: Identifiable {
  public var id: UUID
  public var name: String
  
  public init(id: UUID = UUID(), name: String = "") {
    self.id = id
    self.name = name
  }
}

@DependencyClient
public struct MyModelStore: Sendable {
  public var load: @Sendable (_ id: UUID) async throws -> MyModel?
  public var save: @Sendable (_ model: MyModel) async throws -> Void
}

extension MyModelStore: TestDependencyKey {
  public static let testValue = MyModelStore()
}

extension DependencyValues {
  public var myModelStore: MyModelStore {
    get { self[MyModelStore.self] }
    set { self[MyModelStore.self] = newValue }
  }
}

extension MyModelStore: DependencyKey {
  public static let liveValue: Self = {
    Self(
      load: { _ in return nil },
      save: { _ in }
    )
  }()
}

