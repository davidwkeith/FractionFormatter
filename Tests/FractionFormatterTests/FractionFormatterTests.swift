import XCTest
@testable import FractionFormatter

final class FractionFormatterTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(FractionFormatter().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
