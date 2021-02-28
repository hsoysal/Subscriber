import XCTest
@testable import Subscriber

private struct Product: Subscribable {}

final class SubscriberTokenTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertTrue(true)
    }
    
    override func setUp() {
        super.setUp()
    }
    
    func testSubscriptionToken() {
        let token = [Product].subscribe(block: {_ in})
        XCTAssertNotNil(token, "Subscription Token is nil")
        token?.invalidate()
    }
    
    func testSubscriptionTokenInvalidation() {
        let promise: XCTestExpectation = expectation(description: "promise")
        promise.isInverted = true
        let token = [Product].subscribe { (result) in
            switch result {
            case .update(let items):
                if let _ = items.first as? Product {
                    promise.fulfill()
                }
            default: break
            }
        }
        token?.invalidate()
        [Product()].distribute()
        wait(for: [promise], timeout: 1)
    }
}
