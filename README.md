# Subscriber
Subscriber is a 100% Swift framework to observe class or struct changes in the application. For example; you have a list on the first screen. And you update your class or struct on the second screen. You need to observe the changes on the first page. So, thats why you can use this framework. 

**Features**

* Multiple Databases
* Multiple list of same model


**Instalation**

Subscriber only supports Swift Package Manager at the moment.

.package(url: "https://github.com/hsoysal/Subscriber.git", .upToNextMajor(from: "1.0.0"))
To install Subscriber using Swift Package Manager look for https://github.com/hsoysal/Subscriber.git in Xcode (File/Swift Packages/Add Package Dependency...).

**Usage**


* Register items
```
//To the List of YOURMODEL
let token = Subscriber.current.objects(of: {YOURMODEL}.self).subscribe({ result in
            
    switch result {
        case .initial(let items), .update(let items):
        let yourModels = items as? [{YOURMODEL}]
        ...
    }
})

let token = Subscriber.current.objects(of: {YOURMODEL}.self).subssubscribe(to: "{LIST-ID}", in: "{DATABASE-ID}", block: { result in
            
    switch result {
        case .initial(let items):
        let yourModels = items as? [{YOURMODEL}]
        ...
        case .update(let items)
        let yourModels = items as? [{YOURMODEL}]
        ...
    }
})

//To the Single YOURMODEL having PrimaryKey
let match = Match(name: "M1")
match.subscribe({ (result) in
       if case let SubscriptionResult.initial(items) = result {
           let yourModels: [{YOURMODEL}] = items as? [{YOURMODEL}] ?? []
           yourModels.first
           ...
       }
       else if case let SubscriptionResult.update(items) = result {
           let yourModel = items.first as? {YOURMODEL}
           ...
       }
})
```

* Unregister items

```
token.invalidate()
```

* Distributing Your Single Model
```
let team = Team()
team.ID = "TeamID1"
team.name = "Team 1"
team.distribute()
//team.updateAllMatchingPrimaryKeys()

let team = Team()
team.ID = "TeamID1"
team.name = "Team 1"
team.distribute(in: "{DATABASE-ID}")
//team.updateAllMatchingPrimaryKeys()
//team.updateAllMatchingPrimaryKeys(in: "{DATABASE-ID}")
//team.updateAllMatchingPrimaryKeys(in: "{DATABASE-ID}", "{DATABASE-ID2}")
```

* Distributing Your Multiple Models
```
let team = Team()
team.ID = "TeamID1"
team.name = "Team 1"
let teams:[Team] = [team]
teams.distribute()
//teams.distribute(appending: true)
//teams.updateAllMatchingPrimaryKeys()

let team = Team()
team.ID = "TeamID1"
team.name = "Team 1"
let teams:[Team] = [team]
teams.distribute(in: "{DATABASE-ID}")
//teams.distribute(in: "{DATABASE-ID}", appending: true)
//teams.updateAllMatchingPrimaryKeys(in: "{DATABASE-ID}")
//teams.updateAllMatchingPrimaryKeys(in: "{DATABASE-ID}", "{DATABASE-ID2}")
//teams.updateAllMatchingPrimaryKeys()

let team = Team()
team.ID = "TeamID1"
team.name = "Team 1"
let teams:[Team] = [team]
teams.distribute(to: "{LIST-ID}", in: "{DATABASE-ID}")
//teams.distribute(to: "{LIST-ID}", in: "{DATABASE-ID}", appending: true)
//teams.updateAllMatchingPrimaryKeys()
//teams.updateAllMatchingPrimaryKeys(in: "{DATABASE-ID}")
//teams.updateAllMatchingPrimaryKeys(in: "{DATABASE-ID}", "{DATABASE-ID2}")
```

* Updating Same Model

```
var primaryKey: String? { self.ID } //dynamic
var primaryKey: String? { "id" }    //static
```


**Examples of Subscribing**

First of all, let's define our Models 

```
struct Category {
    var id: String?
    var name: String?
}

extension Category: Subscribable {
    var primaryKey: String? { id }
}

struct Product {
    var id: String?
    var name: String?
}

extension Product: Subscribable {
    var primaryKey: String? { id }
}

//Even Swift Types with primary key
extension String: Subscribable {
    var primaryKey: String? { self }
}
extension Bool: Subscribable {
    var primaryKey: String? { String(self) }
}


//Or you dont have to define primary key
extension String: Subscribable {}
extension Bool: Subscribable {}
```



* List of Categories 
```
private var categories: [Category] = []
private weak var token: SubscriptionToken?

func fetchCategories(completion: (()->Void)?) {
    token = categories.subscribe(block: { [weak self] result in
        guard let self = self else { return }
        if case let .initial(items) = result {
            self.categories = items as? [Category] ?? []
            if items.count == 0 {
                self.fetch(completion: completion) //Fetch them from anywhere else
            }
            else {
                completion?()
            }
        }
        else if case let .update(items) = result {
            self.categories = items as? [Category] ?? []
            completion?()
        }
    })
}

activityIndicatorView.startAnimating()
fetchCategories(completion: {
    self.activityIndicatorView.stopAnimating()
    self.collectionView.reloadData()
})
```

* List of Products of Category A

It subscribes to the list of category's id. So products of different categories will be separated from each other. 
If you wish to hold same product list of same category more than one, you can just give database id.  
```
private var products: [Product] = []
private weak var token: SubscriptionToken?

func fetchProducts(of category: Category, completion: (()->Void)?) {
    //token = products.subscribe(to: category.id, in: "purchased", block: { [weak self] result in
    token = products.subscribe(to: category.id, block: { [weak self] result in
        guard let self = self else { return }
        if case let .initial(items) = result {
            self.products = items as? [Product] ?? []
            if items.count == 0 {
                self.fetch(of: category) //Fetch them from anywhere else
            }
            else {
                completion?()
            }
        }
        else if case let .update(items) = result {
            self.products = items as? [Product] ?? []
            completion?()
        }
    })
}

activityIndicatorView.startAnimating()
fetchProducts(of: currentCategory, completion: { 
    self.activityIndicatorView.stopAnimating()
    self.tableView.reloadData()
})
```

* Product itself

It subscribes to the Product on Product Detail Page, for example. So if this product with primary key has updates somewhere else, it will be updated here too. 

```
private var currentProduct: Product?
private weak var token: SubscriptionToken?

token = currentProduct?.subscribe(block: { [weak self] result in
    guard let self = self else { return }
    switch result {
    case .initial(let items), .update(let items):
        if let product = items.first as? Product {
            self.currentProduct = product
        }
        self.setupUI()
    }
})

// Or you can subscribe in specific database 
token = currentProduct?.subscribe(in: "purchased", block: { [weak self] result in
    guard let self = self else { return }
    switch result {
    case .initial(let items), .update(let items):
        if let product = items.first as? Product {
            self.currentProduct = product
        }
        self.setupUI()
    }
})
```

**Examples of Distributing**

* Category List

```
let categories: [Category] = [...]
categories.distribute()         
categories.distribute(to: "LIST-ID")
categories.distribute(to: "LIST-ID", in: "DATABASE-ID")
categories.distribute(to: "LIST-ID", in: "DATABASE-ID", append: true) //If there is pagination
```

* Product List

```
let products: [Product] = [...]
products.distribute()         
products.distribute(to: currentCategory.id)
products.distribute(to: currentCategory.id, in: "purchased")
products.distribute(to: currentCategory.id, in: "purchased", append: true) //If there is pagination
```

* Product

```
let product: Product
product.distribute()         
product.distribute(in: "purchased")
```

* Distributing models across all lists and databases

You may want all copies of Product or Products to be updated across the application.

```
let product: Product
product.updateAllMatchingPrimaryKeys() //All databases
product.updateAllMatchingPrimaryKeys(in: "default") //Specific databases
product.updateAllMatchingPrimaryKeys(in: "default", "purchased") //Specific databases

let products: [Product]
products.updateAllMatchingPrimaryKeys() //All elements in all databases
products.updateAllMatchingPrimaryKeys(in: "default") //All elements in specific databases
products.updateAllMatchingPrimaryKeys(in: "default", "purchased") //All elements in specific databases
```

**Examples of UI**

There is no primary key on Swift Types like String. Therefore, you can subscribe to a list.
```
@IBOutlet weak var labelTimer: UILabel? {
    didSet {        
        let tick: [String] = []
        let _ = tick.subscribe(to: "timer", block: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .initial(let items), .update(let items):
                self.labelTimer?.text = items.first as? String
            }
        })
    }
}

//Somewhere else, timer distributing date in every second

let formatter: DateFormatter = DateFormatter()
formatter.locale = Locale.current
formatter.dateFormat = "MMM dd, HH:mm:ss"
formatter.timeZone = NSTimeZone.local
let string = formatter.string(from: Date())

[string].distribute(to: "timer")
```

Another example; User  
```
@IBOutlet weak var labelGreeting: UILabel? {
    didSet {        
        let _ = User().subscribe(in: "login", block: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .initial(let items), .update(let items):
                if let user = items.first as? User {
                    self.labelGreeting?.text = "Hello, \(user.name)"
                }
                else {
                    self.labelGreeting?.text = "Please login"
                }
            }
        })
    }
}

//Somewhere else
let user = User()
user.name = "Hasan"
user.distribute(in: "login")

//Logout
Subscriber.current.removeAll(of: User.self, in: "login")
```

Another example; Bool  
```
@IBOutlet weak var labelGreeting: UILabel? {
    didSet {        
        let loggedIn: [Bool] = []
        let _ = loggedIn.subscribe(to: "login status", block: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .initial(let items), .update(let items):
                let bool: Bool = (items.first as? Bool) ?? false
                self.labelGreeting?.text = bool ? "Hello..." : "Please login"
            }
        })
    }
}

//Somewhere else
[true].distribute(to: "login status")
```
