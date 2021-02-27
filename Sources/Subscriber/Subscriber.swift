import Foundation

public typealias SubscriptionResultBlock = (SubscriptionResult)->Void

public protocol Subscribable {
    var primaryKey: String? { get }
}

public extension Subscribable {
    var primaryKey: String? { nil }
}

/**`SubscriptionResult` uses this enum.
*/
public enum SubscriptionResult {
    case initial([Subscribable])
    case update([Subscribable])
}

/**Hold this token to unsubscribe on `deinit`
*/
public class SubscriptionToken {
    
    fileprivate var key: String = ""
    fileprivate init() { }
    public func invalidate() { Subscriber.current.remove(subscription: self) }
}

private class Subscription {
    
    var primaryKey: String
    var database: Subscriber.Database
    var token: String
    var type: String
    var subscription: SubscriptionResultBlock
    
    init(token: String, type: String, primaryKey:String, database: Subscriber.Database, subscription: @escaping SubscriptionResultBlock) {
        self.token = token
        self.type = type
        self.primaryKey = primaryKey
        self.database = database
        self.subscription = subscription
    }
}

fileprivate class SubscriptionCollection {
    var primaryKey: String = "default"
    var database: Subscriber.Database = "default"
    var type: String = ""
    var collection: [Subscribable] = []
}

final public class Subscriber {
    
    public typealias Database = String
    private init() { }
    static let current: Subscriber = Subscriber()
    fileprivate var subscriptions: [Subscription] = []
    fileprivate var collection: [Subscriber.Database:[SubscriptionCollection]] = [:]
    
    /**This will give the list of objects in database `database` default value is `default`
        Also it will give the list of `primaryKey` default value is `default`
        And it will give the models of type `of`
        
        Example:
        cities of Turkey -> primarykey is "turkey" in database "cities"
        cities of Spain -> primarykey is "spain" in database "cities"
        cities of Germany -> primarykey is "germany" in database "cities"
     
        You may want to hold cities of the same countries in a different database. So it wont give the cities in previous example
        Example:
        cities of Turkey -> primarykey is "turkey" in database "capitals"
        cities of Spain -> primarykey is "spain" in database "capitals"
        cities of Germany -> primarykey is "germany" in database "capitals"
    */
    public func objects<T:Subscribable>(of type: T.Type, primaryKey:String = "default", in database: Subscriber.Database = "default") -> [T] {
        
        let type: String = String(describing: type)
        guard let subscriptionCollection = collection[type, primaryKey, database].first else { return [] }
        return subscriptionCollection.collection as! [T]
    }
    
    fileprivate func notify(by type: String, primaryKey: String, database: Subscriber.Database) {
        
        guard let collection:[Subscribable] = self.collection[type, primaryKey, database].first?.collection else { return }
        subscriptions.filter({ $0.type == type && $0.primaryKey == primaryKey && $0.database == database }).forEach({ $0.subscription(.update(collection)) })
    }
}

extension Subscriber {
    fileprivate func append<T:Subscribable>(token: String, type: T.Type, primaryKey:String, database: Subscriber.Database, block: @escaping SubscriptionResultBlock) {
        
        let subscription = Subscription(token: token, type: String(describing: type), primaryKey: primaryKey, database: database, subscription: block)
        subscriptions.append(subscription)
        block(.initial( objects(of: type, primaryKey: primaryKey, in: database) ))
    }
    
    fileprivate func remove(subscription token: SubscriptionToken) {
        subscriptions.removeAll(where: { $0.token == token.key })
    }
}

public extension Array where Element: Subscribable {
    
    /**This will subscribe to a list of objects in database `database` default value is `default`
        Also it will subscribe in the list of `primaryKey` default value is `default`
        So it will hold all list separately
        Example:
        cities of Turkey -> primarykey is "turkey" in database "cities"
        cities of Spain -> primarykey is "spain" in database "cities"
        cities of Germany -> primarykey is "germany" in database "cities"
     
        You may want to hold cities of the same countries in a different database. So it wont override cities in previous example
        Example:
        cities of Turkey -> primarykey is "turkey" in database "capitals"
        cities of Spain -> primarykey is "spain" in database "capitals"
        cities of Germany -> primarykey is "germany" in database "capitals"
    */
    func subscribe(to primaryKey: String? = "default", in database: Subscriber.Database = "default", block:@escaping SubscriptionResultBlock) -> SubscriptionToken? {
        
        let pkey: String = primaryKey ?? "default"
        let key = UUID().uuidString
        Subscriber.current.append(token: key, type: Element.self, primaryKey: pkey, database: database, block: block)
        let subscription = SubscriptionToken()
        subscription.key = key
        return subscription
    }
    
    /**This will distribute to a list of objects in database `database` default value is `default`
        Also it will distributed to the list of `primaryKey` default value is `default`
        If there is appending parameter is true, it will be appended to the list of `primaryKey` in database `database`
        Or it will be replaced with the list just mentioned
        Example:
        a city of Turkey -> primarykey is "turkey" in database "cities"
        a city of Spain -> primarykey is "spain" in database "cities"
        a city of Germany -> primarykey is "germany" in database "cities"
     
        You may want to hold cities of the same countries in a different database. So it wont override cities in previous example
        Example:
        the capital city of Turkey -> primarykey is "turkey" in database "capitals"
        the capital city of Spain -> primarykey is "spain" in database "capitals"
        the capital city of Germany -> primarykey is "germany" in database "capitals"
    */
    func distribute(to primaryKey: String? = "default", in database: Subscriber.Database = "default", append: Bool = false) {
        
        let pkey: String = primaryKey ?? "default"
        let type: String = String(describing: Element.self)
        let collection = SubscriptionCollection()
        collection.primaryKey = pkey
        collection.database = database
        collection.type = type
        if append {
            var objects = Subscriber.current.objects(of: Element.self, primaryKey: pkey, in: database)
            objects.append(contentsOf: self)
            collection.collection = objects
        }
        else {
            collection.collection = self
        }
        Subscriber.current.collection[type, pkey, database] = [collection]
        Subscriber.current.notify(by: type, primaryKey: pkey, database: database)
    }
    
    /**This will update all objects in the array in database `database` default value is `default`
        If there is primary key in model, it will be updated in any list in database `database` otherwise nothing will be done
        You can pass `nil` for database if you want to update it in all databases.
        
        Example:
        a city of Turkey -> primarykey is "turkey" in database "cities"
        
        You may want to hold cities of the same countries in a different database. So it wont override cities in previous example
        Example:
        the capital city of Turkey -> primarykey is "turkey" in database "capitals"
        
        same primary key of same object will be updated in both `cities` and `capitals` databases if database parameter is `nil`
    */
    func updateAllMatchingPrimaryKeys(in database: Subscriber.Database?...) {
        self.forEach({ $0.updateAllMatchingPrimaryKeys() })
        if database.isEmpty { //All databases
            self.forEach({ $0.updateAllMatchingPrimaryKeys() })
        }
        else { //specific databases
            for each in database.compactMap({ $0 }) {
                self.forEach({ $0.updateAllMatchingPrimaryKeys(in: each) })
            }
        }
    }
}

public extension Subscribable {
    
    /**This will subscribe to a single object in database `database` default value is `default`
        So it will hold all list separately
        Example:
        a city of Turkey -> primarykey is "turkey" in database "cities"
        a city of Spain -> primarykey is "spain" in database "cities"
        a city of Germany -> primarykey is "germany" in database "cities"
     
        You may want to hold cities of the same countries in a different database. So it wont override cities in previous example
        Example:
        cities of Turkey -> primarykey is "turkey" in database "capitals"
        cities of Spain -> primarykey is "spain" in database "capitals"
        cities of Germany -> primarykey is "germany" in database "capitals"
    */
    func subscribe(in database: Subscriber.Database = "default", block:@escaping SubscriptionResultBlock) -> SubscriptionToken? {
        
        distribute(in: database)
        let key = UUID().uuidString
        Subscriber.current.append(token: key, type: Self.self, primaryKey: self.primaryKey ?? "default", database: database, block: block)
        let subscription = SubscriptionToken()
        subscription.key = key
        return subscription
    }
    
    /**This will distribute a single object in database `database` default value is `default`
        Also it will distributed to the list of `primaryKey` default value is `default`
        If there is primary key in model, it will be updated in the list of `primaryKey` in database `database`
        Or it will be appended to the list just mentioned
        Example:
        a city of Turkey -> primarykey is "turkey" in database "cities"
        a city of Spain -> primarykey is "spain" in database "cities"
        a city of Germany -> primarykey is "germany" in database "cities"
     
        You may want to hold cities of the same countries in a different database. So it wont override cities in previous example
        Example:
        the capital city of Turkey -> primarykey is "turkey" in database "capitals"
        the capital city of Spain -> primarykey is "spain" in database "capitals"
        the capital city of Germany -> primarykey is "germany" in database "capitals"
    */
    func distribute(in database: Subscriber.Database = "default") {
        
        let primaryKey: String = self.primaryKey ?? "default"
        let type: String = String(describing: Self.self)
        var objects = Subscriber.current.objects(of: Self.self, primaryKey: primaryKey, in: database)
        if let key = self.primaryKey, let index = objects.firstIndex(where: { $0.primaryKey == key }) {
            objects[index] = self
        }
        else {
            objects.append(self)
        }
        let collection = SubscriptionCollection()
        collection.primaryKey = primaryKey
        collection.database = database
        collection.type = type
        collection.collection = objects
        Subscriber.current.collection[type, primaryKey, database] = [collection]
        Subscriber.current.notify(by: type, primaryKey: primaryKey, database: database)
    }
    
    /**This will update a single object with same primary key in database `database` default value is `default`
        If there is primary key in model, it will be updated in any list in database `database` otherwise nothing will be done
        You can pass `nil` for database if you want to update it in all databases.
        
        Example:
        a city of Turkey -> primarykey is "turkey" in database "cities"
        
        You may want to hold cities of the same countries in a different database. So it wont override cities in previous example
        Example:
        the capital city of Turkey -> primarykey is "turkey" in database "capitals"
        
        same primary key of same object will be updated in both `cities` and `capitals` databases if database parameter is `nil`
    */
    func updateAllMatchingPrimaryKeys(in database: Subscriber.Database?...) {
        
        guard let primaryKey = self.primaryKey else { return }
        var all: [SubscriptionCollection] = []
        let databases:[Subscriber.Database] = database.compactMap({$0})
        if databases.isEmpty { //All databases
            for (_, value) in Subscriber.current.collection {
                all.append(contentsOf: value)
            }
        }
        else {
            databases.forEach({ all.append(contentsOf: Subscriber.current.collection[$0] ?? []) })
        }
        
        let type: String = String(describing: Self.self)
        all.filter({ $0.type == type }).forEach({ each in
            if let index = each.collection.firstIndex(where: { $0.primaryKey == primaryKey }) {
                each.collection[index] = self
                Subscriber.current.subscriptions
                    .filter({ $0.type == type && $0.primaryKey == each.primaryKey && $0.database == each.database })
                    .forEach({ $0.subscription(.update(each.collection)) })
            }
        })
    }
}

fileprivate extension Dictionary where Key == Subscriber.Database, Value == [SubscriptionCollection] {
    
    subscript (type: String, key: String = "default", database: String = "default") -> [SubscriptionCollection] {
        get {
            guard let results = self[database] else { return [] }
            return results.filter({ $0.primaryKey == key && $0.type == type })
        }
        set {
            if self[database] == nil { self[database] = [] }
            if let collections = self[database]?.first(where: { $0.primaryKey == key && $0.type == type }) {
                collections.collection = newValue.first?.collection ?? []
            }
            else {
                self[database]?.append(contentsOf: newValue)
            }
        }
    }
}
