# MonoRail

MonoRail is an interface between server-side models and iOS models written entirely in Swift. MonoRail takes the weight of parsing JSON from an API and turning it into useable Swift Objects easy. Furthermore, MonoRail adopts an Active Record-esque approach in handling the creation, retrieval, updating and deletion (CRUD) of models. The easiest way understand MonoRail is to see how simple it is to get a fully functioning RESTful API interface up and running in your app.

[Installation]()

---

### Create a Model ###

```
#!swift

class Train: ActiveModel {

    dynamic var model:String?
    dynamic var numberOfCars:Number?
    dynamic var company:String?

}
```

# Thats It

Use your model with no additional iOS configuration

```
#!swift
// synchronous
let train = Train.get(id: 3)

// asynchronous
Train.get(id: 3, success: { (train:Train) in
    // some code
})

```

## 

All actions involving the backend can be used inline **or with a completion statement**

---

### Get ###
```
#!swift
let train = Train.get(id: 3)

let trains:[Train] = Train.get(where: ["company" : "MonoRail"])
```
Grab records from the server by id or with parameters seamlessly

### Create ###
```
#!swift
let train = Train()
train.numberOfCars = 4
train.save()
```
### Update ###
```
#!swift
let train = Train.get(id: 3)
train.numberOfCars = 8
train.company = "MonoRail"
train.save()
```

### Delete ###
```
#!swift
let train = Train.get(id: 3)
train.delete()

Train.delete(id: 3)
```

---

# Relationships

Building off of the `Train` example, lets make a new model named `Company` and relate the models

```
#!swift

class Train: ActiveModel {

    dynamic var model:String?
    dynamic var numberOfCars:Number?
    dynamic var company:Company?

}
```
```
#!swift

class Company: ActiveModel {

    dynamic var name:String?
    dynamic var city:String?
    dynamic var trains:[Train]?

}
```



---

## Error Handling

```
#!swift
let train = train.get(id: 3)
if train.error {
    // something went wrong
}

Train.get(id: 3, success: { (train:Train) in
    // some code
}, failure: { (error:NSError) in
    // something went wrong
})
```