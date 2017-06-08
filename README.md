# MonoRail

MonoRail is an interface between server-side models and iOS models written entirely in Swift. MonoRail take the weight of parsing JSON from an API into useable Swift Objects easy. Furthermore, MonoRail adopts an Active Record-esque approach in handling the creation, retrieval, updating and deletion (CRUD) of models. The easiest way understand MonoRail is to see how simple it is to get a fully functioning API interface up an running in your app.


---

### Up and Running in Seconds ###

```
#!swift
import MonoRail
```
### Set a root URL for the API ###
```
#!swift
MonoRail.register(apiRootUrl: "https://url.to/your/api")
```
The best place to put this is in the AppDelegate's `application: didFinishLaunchingWithOptions:`
### Create a Model ###
```
#!swift

class Train: ActiveModel {

    dynamic var model:String
    dynamic var numberOfCars:Number
    dynamic var company:String

}
```
## Thats It. ##
You are now ready to start using your model!