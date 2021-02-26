# Subscriber
Subscriber is a 100% Swift framework to observe class or struct changes in the application. For example; you have a list on the first screen. And you update your class or struct on the second screen. You need to observe the changes on the first page. So, thats why you can use this framework. 

**Features**

Multiple Databases
Multiple list of same model


**Instalation**

Subscriber only supports Swift Package Manager at the moment.

.package(url: "https://github.com/hsoysal/Subscriber.git", .upToNextMajor(from: "1.0.0"))
To install Subscriber using Swift Package Manager look for https://github.com/hsoysal/Subscriber.git in Xcode (File/Swift Packages/Add Package Dependency...).

**Usage**


* Register items
```
//To the List of YOURMODEL
let token = Subscriber.current.objects(of: {YOURMODEL}.self).subscribe({ result in
            
      if case let SubscriptionResult.initial(items) = result {
          let teams: [{YOURMODEL}] = items as? [{YOURMODEL}] ?? []
          ...
      }
      else if case let SubscriptionResult.update(items) = result {
        let teams: [{YOURMODEL}] = items as? [{YOURMODEL}] ?? []
        ...
      }
})

let token = Subscriber.current.objects(of: {YOURMODEL}.self).subssubscribe(to: "{LIST-ID}", in: "{DATABASE-ID}", block: { result in
            
      if case let SubscriptionResult.initial(items) = result {
          let teams: [{YOURMODEL}] = items as? [{YOURMODEL}] ?? []
          ...
      }
      else if case let SubscriptionResult.update(items) = result {
        let teams: [{YOURMODEL}] = items as? [{YOURMODEL}] ?? []
        ...
      }
})

//To the Single YOURMODEL having PrimaryKey
let match = Match(name: "M1")
match.subscribe({ (result) in
       if case let SubscriptionResult.initial(items) = result {
           let matches: [Match] = items as? [Match] ?? []
           matches.first
           ...
       }
       else if case let SubscriptionResult.update(items) = result {
           let matches: [Match] = items as? [Match] ?? []
           matches.first
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
//team.updateAllMatchingPrimaryKeys(in: nil)

let team = Team()
team.ID = "TeamID1"
team.name = "Team 1"
team.distribute(in: "{DATABASE-ID}")
//team.updateAllMatchingPrimaryKeys(in: "{DATABASE-ID}")
//team.updateAllMatchingPrimaryKeys(in: nil)
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

let team = Team()
team.ID = "TeamID1"
team.name = "Team 1"
let teams:[Team] = [team]
teams.distribute(to: "{LIST-ID}", in: "{DATABASE-ID}")
//teams.distribute(to: "{LIST-ID}", in: "{DATABASE-ID}", appending: true)
//teams.updateAllMatchingPrimaryKeys(in: nil)
```

* Updating Same Model
```
var primaryKey: String? { self.ID }
```




