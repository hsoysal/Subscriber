import XCTest
@testable import Subscriber

private struct Product: Subscribable {}

final class SubscriberListTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertTrue(true)
    }
    
    override func setUp() {
        super.setUp()
        Product.removeAll()
    }
    
    func testInitialDistribution() {
        let product = Product()
        product.distribute()
        let promise: XCTestExpectation = XCTestExpectation(description: "promise")
        promise.isInverted = true
        let token = [Product].subscribe { (result) in
            switch result {
            case .initial(let items):
                XCTAssertTrue(items.count == 1, "Initial Distribution does not have 1 object")
            case .update(_):
                promise.fulfill()
            }
        }
        token?.invalidate()
        
        let token2 = [Product].subscribe(to: "another-list", block: { (result) in
            switch result {
            case .initial(let items):
                XCTAssertTrue(items.count == 0, "Initial Distribution does not have 0 object")
            default: break
            }
        })
        token2?.invalidate()
        
        wait(for: [promise], timeout: 1)
    }
    
    func testRemovalOfAll() {
        
        let product = Product()
        product.distribute()
        Product.removeAll()
        
        let promise1: XCTestExpectation = XCTestExpectation(description: "promise1")
        let promise2: XCTestExpectation = XCTestExpectation(description: "promise1")
        
        let token = [Product].subscribe { (result) in
            switch result {
            case .initial(let items):
                XCTAssertTrue(items.count == 0, "Initial Distribution does not have 0 object")
            case .update(let items):
                if items.count == 1 { promise1.fulfill() }
                if items.count == 0 { promise2.fulfill() }
            }
        }
        
        product.distribute()
        Product.removeAll()
        token?.invalidate()
    }
    
    func testUpdateDistribution() {
        let product = Product()
        product.distribute()
        let token = [Product].subscribe { (result) in
            switch result {
            case .initial(let items):
                XCTAssertTrue(items.count == 1, "Initial Distribution does not have 1 object")
            case .update(let items):
                XCTAssertTrue(items.count == 2, "Update Distribution does not have 2 objects")
            }
        }
        [Product(), Product()].distribute(to: nil)
        let token2 = [Product].subscribe(to: nil, block: { (result) in
            switch result {
            case .initial(let items):
                XCTAssertTrue(items.count == 2, "Initial Distribution does not have 2 objects")
            default: break
            }
        })
        token2?.invalidate()
        token?.invalidate()
    }
    
    func testAppending() {
        let product = Product()
        product.distribute()
        let promise1: XCTestExpectation = XCTestExpectation(description: "promise1")
        let promise2: XCTestExpectation = XCTestExpectation(description: "promise1")
        let token = [Product].subscribe { (result) in
            switch result {
            case .initial(let items):
                XCTAssertTrue(items.count == 1, "Appending does not have 1 object")
            case .update(let items):
                if items.count == 2 { promise1.fulfill() }
                if items.count == 4 { promise2.fulfill() }
            }
        }
        [Product(), Product()].distribute()
        [Product(), Product()].distribute(append: true)
        wait(for: [promise1, promise2], timeout: 2)
        token?.invalidate()
    }
}
