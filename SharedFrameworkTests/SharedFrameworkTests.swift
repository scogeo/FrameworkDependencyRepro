import Dependencies
import Foundation
import SharedModels
import Testing
@testable import SharedFramework

struct SharedFrameworkTests {

    @Test func testSTore() async throws {
      @Dependency(\.myModelStore) var myModelStore
    
      #expect(try await myModelStore.load(id: UUID()) == nil)
    }

}
