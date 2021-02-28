import XCTest
@testable import Subscriber

private struct Product: Subscribable {
    var id: String = ""
    var name: String = ""
    var primaryKey: String? { id }
}

private struct Category: Subscribable {
    var id: String = ""
    var name: String = ""
}

final class SubscriberPrimaryKeyTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertTrue(true)
    }
    
    override func setUp() {
        super.setUp()
        Product.removeAll()
        Category.removeAll(in: "default")
    }
    
    func testDifferentListIDSubscription() {
        let product = Product(id: "1", name: "1-1")
        product.distribute()
        let token = [Product].subscribe { (result) in
            switch result {
            case .initial(let items):
                let p = items.first as? Product
                XCTAssertNil(p, "Object is not nil")
            default: break
            }
        }
        token?.invalidate()
    }
    
    func testSameListIDSubscription() {
        let product = Product(id: "1", name: "1-1")
        product.distribute()
        let token = [Product].subscribe(to: "1", block: { (result) in
            switch result {
            case .initial(let items):
                let p = items.first as? Product
                XCTAssertEqual(p?.id, "1", "ID is not equal to 1")
                XCTAssertEqual(p?.name, "1-1", "name is not equal to 1-1")
            default: break
            }
        })
        token?.invalidate()
    }
    
    func testSamePrimaryIDSubscription() {
        var product = Product(id: "1", name: "1-1")
        product.distribute()
        
        let token = product.subscribe(block: { (result) in
            switch result {
            case .initial(let items):
                let p = items.first as? Product
                XCTAssertEqual(p?.id, "1", "ID is not equal to 1")
                XCTAssertEqual(p?.name, "1-1", "name is not equal to 1-1")
            case .update(let items):
                let p = items.last as? Product
                XCTAssertEqual(p?.id, "1", "ID is not equal to 1")
                XCTAssertEqual(p?.name, "1-2", "name is not equal to 1-2")
            }
        })
        product.name = "1-2"
        product.distribute()
        token?.invalidate()
    }
    
    func testSubscriptionWithoutPrimaryID() {
        var category = Category(id: "1", name: "1-1")
        category.distribute()
        category.distribute()
        
        let promise1: XCTestExpectation = XCTestExpectation(description: "promise1")
        let promise2: XCTestExpectation = XCTestExpectation(description: "promise2")
        
        let token = category.subscribe(block: { (result) in
            switch result {
            case .initial(let items):
                let c = items.first as? Category
                XCTAssertTrue(items.count == 2, "Initial category count is not 2")
                XCTAssertEqual(c?.id, "1", "ID is not equal to 1")
                XCTAssertEqual(c?.name, "1-1", "name is not equal to 1-1")
            case .update(let items):
                
                XCTAssertTrue(items.count == 3, "Update category count is not 3")
                let c = items.first as? Category
                if c?.id == "1" && c?.name == "1-1" { promise1.fulfill() }
                let c2 = items.last as? Category
                if c2?.id == "1" && c2?.name == "1-2" { promise2.fulfill() }
            }
        })
        category.name = "1-2"
        category.distribute()
        token?.invalidate()
        
        category.name = "1-3"
        category.updateAllMatchingPrimaryKeys()
        
        wait(for: [promise1, promise2], timeout: 2)
    }
    
    func testSubscriptionInDifferentDatabaseWithoutPrimaryID() {
        let differentDatabase = "different-db"
        var category = Category(id: "1", name: "1-1")
        category.distribute(in: differentDatabase)
        category.distribute()
        
        let promise1: XCTestExpectation = XCTestExpectation(description: "promise1")
        let promise2: XCTestExpectation = XCTestExpectation(description: "promise2")
        
        let token = category.subscribe(in: differentDatabase, block: { (result) in
            switch result {
            case .initial(let items):
                let c = items.first as? Category
                XCTAssertTrue(items.count == 1, "Initial category count is not 1")
                XCTAssertEqual(c?.id, "1", "ID is not equal to 1")
                XCTAssertEqual(c?.name, "1-1", "name is not equal to 1-1")
            case .update(let items):
                
                XCTAssertTrue(items.count == 2, "Update category count is not 3")
                let c = items.first as? Category
                if c?.id == "1" && c?.name == "1-1" { promise1.fulfill() }
                let c2 = items.last as? Category
                if c2?.id == "1" && c2?.name == "1-2" { promise2.fulfill() }
            }
        })
        category.name = "1-2"
        category.distribute(in: differentDatabase)
        token?.invalidate()
        
        category.name = "1-3"
        category.updateAllMatchingPrimaryKeys(in: differentDatabase)
        
        wait(for: [promise1, promise2], timeout: 2)
    }
    
    func testUpdatingPrimaryIDSubscription() {
        var product = Product(id: "1", name: "1-1")
        product.distribute()
        
        let promise1: XCTestExpectation = XCTestExpectation(description: "promise1")
        let promise2: XCTestExpectation = XCTestExpectation(description: "promise2")
        let promise3: XCTestExpectation = XCTestExpectation(description: "promise3")
        
        let token = product.subscribe(block: { (result) in
            switch result {
            case .initial(let items):
                let p = items.first as? Product
                XCTAssertEqual(p?.id, "1", "ID is not equal to 1")
                XCTAssertEqual(p?.name, "1-1", "name is not equal to 1-1")
            case .update(let items):
                let p = items.last as? Product
                if p?.id == "1" && p?.name == "1-2" { promise1.fulfill() }
                if p?.id == "1" && p?.name == "1-3" { promise2.fulfill() }
                if p?.id == "1" && p?.name == "1-4" { promise3.fulfill() }
            }
        })
        product.name = "1-2"
        product.updateAllMatchingPrimaryKeys()
        product.name = "1-3"
        [product].updateAllMatchingPrimaryKeys(in: "default")
        product.name = "1-4"
        [product].updateAllMatchingPrimaryKeys()
        token?.invalidate()
        wait(for: [promise1, promise2], timeout: 2)
    }
}
