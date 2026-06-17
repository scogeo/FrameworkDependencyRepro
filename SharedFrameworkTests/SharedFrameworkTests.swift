import Dependencies
import Foundation
import SharedModels
import Testing
@testable import SharedFramework

struct SharedFrameworkTests {

    @Test func testStore() async throws {
      @Dependency(\.myModelStore) var myModelStore
    
      #expect(await myModelStore.load(id: UUID()) == nil)
    }

}
