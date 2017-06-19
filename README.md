![MonoRail - Swift on Rails](README/monorail_logo.png)

MonoRail is an interface between server-side models and iOS models written entirely in Swift. MonoRail takes the weight of parsing JSON from an API and turning it into useable Swift objects easy. Furthermore, MonoRail adopts a Ruby on Rails-esque approach in handling the creation, retrieval, updating and deletion (CRUD) of models. The easiest way to understand the benefits of MonoRail is to see how simple it is to get a functioning REST API interface up and running in seconds.

### Give MonoRail an API Address
```swift
MonoRail.register(apiRootUrl: "URL TO REST API")
```
Add this in the Application Delegate's `application: didFinishLaunchingWithOptions:`

### Create a model
```swift
class Train: ActiveModel {
    var company = String.Field
    var numberOfCars = Number.Field
    var maxSpeed = Number.Field
}
```

### Thats It

```swift
let train = Train.get(id: 1)

print(train.id)             // 1
print(train.company)        // MonoRail Co.
print(train.numberOfCars)   // 5
print(train.maxSpeed)       // 46.8
```

[More about models](#more-on-models)

### Create, Retrieve, Update and Delete

```swift
let train = Train()
train.company = "MonoRail Co."
train.create()

train.maxSpeed = 46.8
train.save()

let allTrains = Train.get()
for aTrain in allTrains {
    print(aTrain.company)
}

train.delete()

```
[More about actions](#actions)

## Relationships
MonoRail is much more than just a JSON de/serializer and some server interaction, one of the core features of MonoRail, and an integral aspect to any API, is relational models. MonoRail does all the hard work for you.

### Create models
```swift
class Car: ActiveModel, ActiveReference {
    var occupancy = Number.Field
    var needsRepairs = Boolean.Field
    var train = References(Train.One)
}

class Conductor: ActiveModel, ActiveReference {
    var name = String.Field
    var train = References(Train.One)
}

class Train:ActiveModel, ActiveReference {
    var company = String.Field
    var maxSpeed = Number.Field
    var cars = Has(Car.ImbedsMany) // an array of car objects are imbedded in the JSON response
    var conductor = Has(Conductor.ImbedsOne)
}
```

### Thats it
```swift
let train = Train.get(id: 1)

for car in train.cars {
    print(car.occupancy)
}
```

[More about relationships](#relationships-in-detail)

## Application-Wide Persistence 

When two instances of the same `type` and the same `id` exist in the application, their fields are synchronized with the most recently fetched model. Furthermore, if two instances of the same `type` and `id` exist, MonoRail attempts to consolidate them so there is only one instance being used across the application, minimizing memory usage.

Example:

```swift
let train = Train.get(id: 1)
let anotherTrain = Train.get(id: 1)

print(anotherTrain.maxSpeed)    // 46.8

train.maxSpeed = 55.5
train.save()

print(anotherTrain.maxSpeed)    // 55.5
```

### Relationships are Persisted too
Example:
```swift
let trainA = Train.get(id: 1)
let trainB = Train.get(id: 2)

let conductor = trainA.conductor
conductor.train = trainB
conductor.save()

print(trainA.conductor.name)   // nil
print(trainB.conductor.name)   // Bill

```
A use case for this could be having a `UIViewController` get a Train and display all of it's Cars. When a user taps on a Car, a modal ViewController pops up that allows the user to edit the information of a Train Car. When the user saves the information, the modal ViewController is dismissed and in the original ViewController, the Car instance owned by the Train instance is automatically updated with the new information. All of this done without any work by you and in only one API call.

---

# Installation

For now, clone the repository and include the xcode project in your project

---

# Documentation

## More on Models

All of your models in MonoRail must subclass `ActiveModel`. ActiveModel does a **lot** of things for you, such as CRUD actions, serializing and deserializing JSON requests/responses, automatically persisting fields across instances, interpreting field types (including relationship types and related model types) without the need for any additional configuration on your part (unless you need it), and many other things in between.

Example:

```swift
class Train: ActiveModel {
    var company = String.Field
    var maxSpeed = Number.Field
}
```
As described earlier, creating a model is as simple as creating a class and defining fields.

### Fields

Available fields for use with MonoRail. MonoRail requires that you use the `Field` static variable of each type listed below.

| Type    | Usage         | Description                                                                                                                             |
|---------|---------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| String  | `String.Field`  | Normal Swift String                                                                                                                     |
| Number  |` Number.Field`  | `NSNumber` with added functionality and operation overloads that make it act as an int/double/float/etc. literal                          |
| Boolean | `Boolean.Field` | TypeAlias of Number. Use it only to make your model more understandable. comparison with ` == true` and assigning `= true` work like a normal `bool` |
| Date    | `Date.Field`    | Normal Swift Date. Expects date to be formatted by Rails `yyyy-MM-dd'T'HH:mm:ss.SSSZ`                                                   |
| Hash    | `Hash.Field`    | TypeAlias of `NSDictionary`, you can use NSDictionary.Field in place of Hash                                                              |
| List    | `List.Field`    | TypeAlias of `NSArray`, you can use NSArray.Field in place of List                                                                        |
| Enum    | `Enum.Field`    | Explanation below |

Example usage:

```swift
var string = String.Field
var number = Number.Field
var boolean = Boolean.Field
var date = Date.Field
// etc.

```

**IMPORTANT NOTE** As of now, changing which field in the JSON response is tied to a variable cannot be done inline. The `nameOfYourVariable` will be tied to the snake cased `name_of_your_variable`. In future releases I will aim to fix this. However, by utilizing `customSerializer` and `customDeserializer` you can map the JSON anyway you want. More details below

### Customization

`ActiveModel` makes some assumptions about the naming of your model, its path relative to the `apiRootUrl`, and the formatting of the JSON response. If these are assumptions are wrong, you can change them.

Override the `register()` function in your model to rename it and set its path, and override `customSerialize()` and `customDeserialize()` to handle the parsing from JSON to a usable model and vice-versa.

```swift
class Resource:ActiveModel {

    override class func register() {
        set(name: "NEW NAME", plural: "PLURALIZED NEW NAME")          // default is the class name and the class name plural
        set(path: "path/to/resource")                                 // default is "/"
    }

    override class func customDeserialize(dictionary:NSDictionary) -> Resource? {
        // use the dictionary to populate and return an instance of your model
    }
    
    override class func customSerialize(model:ActiveModel, action:ActiveModel.Action? = nil) -> Dictionary<String, Any?>? {
        // use the model to generate a dictionary. This dictionary will be converted to JSON or URL (GET) parameters.
    }

}
```
### Actions
There are `Class` actions and `Instance` actions, class actions are defined as `class func ...` and instance actions are defined as `func ...`.

Example:

```swift
Train.get(id: 1)     // Class action

let train = Train()
train.create()       // Instance action
```

| Type | Scope    | Usage          | Description                                                                                   |
|------|----------|----------------|-----------------------------------------------------------------------------------------------|
| GET  | Class    | `get(id: )`    | Request a single resource with an id of type `int` or `String`                                |
| GET  | Class    | `get(where: )` | Request an array of resources by passing a given `Dictionary<String, Any?>` as parameters     |
| GET  | Class    | `get()`        | Request an array of resources by passing no id or parameters                                  |
| POST | Instance | `create()`     | Post request to create the model                                                              |
| PUT  | Instance | `save()`       | Put request to update the current model. If the model is not created, it will call `create()` |
| GET  | Instance | `fetch()`      | Calls `get(id:)` and updates the instance with current data                                   |

Actions can be called synchronously and asynchronously (in this ReadMe, the synchronous version is used only because it is less code. It is recommended that you use the asynchronous method)

#### Synchronous
```swift
let train = Train.get(id: 1)
```

#### Asynchronous
```swift
Train.get(id: 1, success: { (train:Train) in
   // code            
})
```
Failure block is optional:
```swift
Train.get(id: 1, success: { (train:Train) in
    // code            
}, failure: { (error:ActiveNetworkError) in
    // code
})
```
The failure block receives an instance of `ActiveNetworkError`

> **ActiveNetworkError** has instance variables `domain`, `code`, and `data`

> * **domain**   `String` the domain of the error, example: `Not Found`

> * **code**     `Int` the response code of the error, example: `404`

> * **data**     `NSDictionary?` the body of the error response, example: `{ "errors" : { "This resource does not exist" } }`

## API Requirements 

MonoRail has very minor requirements for your API for it to work out of the box without any customization by you, and for most RESTful APIs, these requirements will already be in place.

### Endpoints

These are the required endpoints for a default ActiveModel in MonoRail. You can customize your model to remove actions as you wish (explained below).

For the model `Resource`: 

| Action | Endpoint       | Description                                                                                                                                                                                                                                                                                                                                 |
|--------|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| GET    | /resources     | Get a collection of resources. **NOTE:** this endpoint must accept filter parameters, example `{ "related_id" : 1 }` should respond with a collection of resources who's `related_id` field is equal to 1. MonoRail uses this to fetch related resources that are not referenced directly by the model (explained in further detail below)  |
| GET    | /resources/:id | Normal REST API `get` request. Responds with a single resource                                                                                                                                                                                                                                                                              |
| POST   | /resources     | Normal REST API `post` request. Creates a new resource and responds with the newly created resource                                                                                                                                                                                                                                         |
| PUT    | /resources/:id | Normal REST API `put` request. Updates the resource and responds with the updated resource                                                                                                                                                                                                                                                  |
| DELETE | /resources/:id | Normal REST API `delete` request. Deletes the resource and responds with a status code in the 200 range    

`ActiveModel` implements a `get(where: )` action that hits the `GET /resources` endpoint with parameters that it expects will be used to filter the response. Implementing this functionality in a Rails API is quite easy:

```ruby
if params.empty?
    render json: { resources: Resource.all }
else
    render json: { animals: Resource.where(params) }
end
```

### JSON Format

MonoRail makes a lot of assumptions in order to take a bulk of the work off of your hands, and most of these assumptions have to do with JSON.

#### Expected Response Body

When a *single* resource is requested in `GET`, `POST` and `PUT` requests, MonoRail expects this format:

```json
{
    "resource" : {
        "id" : 1,
        "field" : "a field of text",
        "snake_cased" : true,
    }
}
```

And when *multiple* resources and/or *imbedded* resources are expected:

```json
{
    "resource" : {
        "id" : 1,
        "objects" : [
            {
                "id" : 12,
                "field" : true
            },
            {
                "id" : 6,
                "field" : false
            }
        ]
    }
}
```
**NOTE** that MonoRail requires that the naming convention is to use `snake_case` for singular fields and the pluralization of the resource name for collections. This can be changed for related fields, but not for unrelated fields.

For APIs that use Rails and adopt RESTful aspects, this shouldn't be an issue, however in later releases aliasing for unrelated fields will be implemented.

## Relationships in Detail

Using `ActiveReference` in addition to `ActiveModel` enables your models to reference one another. Adding relationships to models is as simple as adding the `ActiveReference` protocol and defining a reference field.

```swift
class Car: ActiveModel, ActiveReference {
    var train = References(Train.One)
}

class Train: ActiveModel, ActiveReference {
    var cars = Has(Car.Many)
}
``` 
In this example, a `Car` references a single `Train`. In the JSON, this reference is at the field `train_id`, MonoRail makes the assumption that the reference at the variable `train` is tied to `train_id` (this can be changed, explained below).

**NOTE** the use of `References` and `Has`, which are *Relationship Types*, and `One` and `Many`, which are *Relationship Modifiers*

### Relationship Modifiers

Tells MonoRail what it should expect at the field in the response for a related resource.

| Modifier   | Description                                                                                                                     |
|------------|---------------------------------------------------------------------------------------------------------------------------------|
| One        | The field relates to a single other resource                                                                                    |
| Many       | The field relates to many other resources                                                                                       |
| ImbedsOne  | The field relates to a single other resource which it expects to be imbedded in the JSON response                               |
| ImbedsMany | The field relates to many other resources, in which all of the other resources are expected to be imbedded in the JSON response |

### Relationship Types

| Type       | Description                                                                                                                                                                                                                                                                                                     |
|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| References | Makes a direct reference to the `id` of another resource (or if it's imbedded, the server-side model makes a direct reference). Much less common, but if the server-side model references many other resources, `Reference(Resource.Many)` expects an array of `id`s which directly reference another resource. |
| Has        | Another resource or many other resources directly reference the model by its `id`                                                                                                                                                                                                                               |
| BelongsTo  | An alias for `Has`  **NOTE** may be deprecated, avoid using                                                                                                                                                                                                                                                     |

`ActiveModel` and `ActiveReference` make a lot of assumptions about the naming and 

### Customize Relationship Fields

References( `type` :ActiveModel.Type, `at` :String?, `aliasing` :String?, `referenceIdField` :String?, `inverseOf` :String?)

* `at` the name of the instance variable in the model object. Defaults to the model type's name in camelCase
* `aliasing` the name of the field in the JSON response. Defaults to the `snake_cased` name of the variable and adds an "_id" if it is a non-embedded single reference
* `referenceIdField` the name of the id field that this field will serialize to. Will use the alias and the relationship type default to "related_model_id" or "related_models"
* `inverseOf` the name of the variable (in another model class) that relates to this model


Has( `type` :ActiveModel.Type, `at` :String?, `aliasing` :String?, `foreignKey` :String?) 

* `at` the name of the instance variable in the model object. Defaults to the model type's name in camelCase
* `aliasing` the name of the field in the JSON response. Is not used unless the related model is imbedded! Defaults to the name of the variable
* `foreignKey` the name of the foreign key of this model in the related model (the name used in the api). Defaults to the name of the class of the given type, adding "_id" or pluralizing when appropriate


Example:
```swift
var monorail = References(Train.ImbedsOne, at: "monorail", aliasing: "monorail")
var employee = References(Conductor.One, at: "employee", aliasing: "conductor_id")
```

**NOTE** Reference, Has, and BelongsTo assumes that the name of the variable is the model type's name in camelCase. If it isn't, you need to set it with `at`.

# Networking Delegate

If you need to set default headers, default parameters, and/or get information from the response headers after each request MonoRail makes, use `NetworkingDelegate`

Required functions:

```swift
public protocol NetworkingDelegate {
    func newResponse(headers:Dictionary<String, Any?>)
    func additionalHeaders() -> Dictionary<String, Any?>
    func additionalParameters() -> Dictionary<String, Any?>
}
```

Set the delegate:

```swift
Networking.delegate = MyNetworkingDelegate()
```

You can set this in the AppDelegate's `application: didFinishLaunchingWithOptions:`
