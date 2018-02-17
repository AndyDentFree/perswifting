// Initial Playground - a hierarchy

import Foundation

class BaseBeast {
  let name: String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
}

class Flyer : BaseBeast {
  let maxAltitude:Int
  init(name:String, maxAltitude:Int) {
    self.maxAltitude = maxAltitude
    super.init(name: name)
  }
  override func move() -> String { return "\(name) Flies up to \(maxAltitude)"}
}


class Walker : BaseBeast {
  let numLegs: Int
  let hasTail: Bool
  init(name:String, legs:Int=4, hasTail:Bool=true) {
    self.numLegs = legs
    self.hasTail = hasTail
    super.init(name: name)
  }
  override func move() -> String {
    if numLegs == 0 {
      return "\(name) Wriggles on its belly"
    }
    let maybeWaggle = hasTail ? "waggling its tail" : ""
    return "\(name) Runs on \(numLegs) legs \(maybeWaggle)"
  }
}


struct Zoo {
  var creatures = [BaseBeast]()
}

let startZoo = Zoo(creatures: [
  Flyer(name:"Kookaburra", maxAltitude:5000),
  BaseBeast(name:"Rock"),
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  Walker(name:"Geek", legs:2, hasTail:false)
  ])


startZoo.creatures.forEach { print($0.move()) }
