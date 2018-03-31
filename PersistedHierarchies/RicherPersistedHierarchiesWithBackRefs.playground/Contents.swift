//: RicherPersistedHierarchiesWithBackRefs - use class hierarchy which is not trivially Codable
//: See the Codable.Hierarchies folder for an explanation and an alternative
//: **Assume you have to use inheritance** and want to put those types into a heterogenous array of the base type
//: **Note** for flexibility in registration, this string keys for factory lookup rather than integers
//: there are tricks we could use to directly derive a Hashable from the type but would not be safely persistent
//: Extends the example and support clases in RicherPersistedHierarchies to handle optionals and references.

import Foundation

//:---- Example things using HierCodable

struct Phone : HierCodable {
  enum osType:Int {
    case Android=1
    case iPhone=99
  }
  
  let number:Int
  let os:osType
  
  init(number:Int, os:osType = .iPhone) {
    self.os = os
    self.number = number
  }
  
  func describe() -> String {
    switch os {
    case .Android:
      return "\(number) stuck with droid update"
    default:
      return "\(number) waiting for Siri"
    }
  }

  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"ph") {
    (from) in
    return try Phone(number:from.read(), os:osType(rawValue: from.read())!)
  }
  func typeKey() -> String { return Phone.typeCode }
  func encode(to:HierEncoder) {
    to.write(number)
    to.write(os.rawValue)
  }
}

class BaseBeast : HierCodable {
  let name: String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
  
  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"BB") {
    (from) in
    return try BaseBeast(name:from.read())
  }
  func typeKey() -> String { return BaseBeast.typeCode }
  func encode(to:HierEncoder) {
    to.write(name)
  }
}

class Flyer : BaseBeast {
  let maxAltitude:Int
  let airSpeed:Int?
  init(name:String, maxAltitude:Int, airSpeed:Int?=nil) {
    self.maxAltitude = maxAltitude
    self.airSpeed = airSpeed
    super.init(name: name)
  }
  override func move() -> String {
    if airSpeed != nil {
      return "\(name)  Flies up to \(maxAltitude) at \(airSpeed!) m/s"
    }
    return "\(name)  Flies up to \(maxAltitude)"
  }

  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"F") {
    (from) in
    return try Flyer(name:from.read(), maxAltitude:from.read(), airSpeed:from.read())
  }
  override func typeKey() -> String { return Flyer.typeCode }
  override func encode(to:HierEncoder) {
    super.encode(to:to)
    to.write(maxAltitude)
    to.write(airSpeed)
  }
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

  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"W") {
    (from) in
    return try Walker(name:from.read(), legs:from.read(), hasTail:from.read())
  }
  override func typeKey() -> String { return Walker.typeCode }
  override func encode(to:HierEncoder) {
    super.encode(to:to)
    to.write(numLegs)
    to.write(hasTail)
  }
}

class Human : Walker {
  let phones:[Phone]
  
  init(name:String, phones:[Phone]=[]) {
    self.phones = phones
    super.init(name:name, legs:2, hasTail: false)
  }
  override func move() -> String {
    let maybePhones = phones.count > 0 ? "phones: " + phones.map {$0.describe()}.joined(separator:", ") : "has no phone"
    return "\(name) \(maybePhones)"
  }
  

  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"H") {
    (from) in
    return try Human(name:from.read(), phones:from.readArray() as! [Phone])
  }
  override func typeKey() -> String { return Human.typeCode }
  override func encode(to:HierEncoder) {
    // SKIPPED super.encode(to:to)  // Walker super also writes members we hardcode, so we just write the member we care about
    to.write(name)
    to.write(phones)
  }

}

struct Zoo : HierCodable {
  var creatures = [BaseBeast]()
  func dump() {
    creatures.forEach { print($0.move()) }
  }
  
  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"Zoo") {
    (from) in
      let creaturesDecoded = (try? from.readArray()) ?? [HierCodable]()
      return Zoo(creatures:creaturesDecoded as! [BaseBeast])
    }
  func typeKey() -> String { return Zoo.typeCode }
  func encode(to:HierEncoder) {
    to.write(creatures)
  }
}


//: ---- Demo of encoding and decoding working ----

// Create Zoo
let startZoo = Zoo(creatures: [
  Flyer(name:"Kookaburra", maxAltitude:5000),
  BaseBeast(name:"Rock"),
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  Human(name:"Geek", phones:[Phone(number:555111222, os:.Android), Phone(number:666)]),
  Human(name:"PHB")
  ])
print("Original Zoo")
startZoo.dump()

//: ---- Using a simple encoder
print("\nEncoding Zoo to binary")
let binData = SimpleHierBinaryEncoder().encode(startZoo)

print("\nDecoding Zoo from binary")
let dec = SimpleHierBinaryDecoder(decodeFrom:binData)
let decodedZoo:Zoo? = try dec.decode()

print("\nDecoded Zoo")
decodedZoo?.dump()

let textDump = SimpleDebuggingTextEncoder().encode(startZoo)
print("\n\nSimpleDebuggingTextEncoder dump")
print(textDump)

