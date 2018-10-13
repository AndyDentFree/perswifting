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
    return try Phone(number:from.dech(), os:osType(rawValue: from.dech())!)
  }
  func typeKey() -> String { return Phone.typeCode }
  func encode(to:HierEncoder) {
    to.ench(number)
    to.ench(os.rawValue)
  }
}

class BaseBeast : HierCodable {
  let name: String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
  
  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"BB") {
    (from) in
    return try BaseBeast(name:from.dech())
  }
  func typeKey() -> String { return BaseBeast.typeCode }
  func encode(to:HierEncoder) {
    to.ench(name)
  }

  //MARK HierCodable optional for stuff with target refs
  private var _hasPersistentReference = false
  public func persistsReference(from:HierCodable) {
    // ignores how many times called
    _hasPersistentReference = true
  }
  
  public func hasPersistentReference() -> Bool
  {
    return _hasPersistentReference
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
    return try Flyer(name:from.dech(), maxAltitude:from.dech(), airSpeed:from.dech())
  }
  override func typeKey() -> String { return Flyer.typeCode }
  override func encode(to:HierEncoder) {
    super.encode(to:to)
    to.ench(maxAltitude)
    to.ench(airSpeed)
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
    return try Walker(name:from.dech(), legs:from.dech(), hasTail:from.dech())
  }
  override func typeKey() -> String { return Walker.typeCode }
  override func encode(to:HierEncoder) {
    super.encode(to:to)
    to.ench(numLegs)
    to.ench(hasTail)
  }
}

class Human : Walker {
  let phones:[Phone]
  let boss:Human?
  init(name:String, phones:[Phone]=[], boss:Human?=nil) {
    self.phones = phones
    self.boss = boss
    super.init(name:name, legs:2, hasTail: false)
    boss?.persistsReference(from:self)
  }
  override func move() -> String {
    let maybePhones = phones.count > 0 ? "phones: " + phones.map {$0.describe()}.joined(separator:", ") : "has no phone"
    let maybeBoss = boss == nil ? "" : "trying to contact boss \(boss!.name)"
    return "\(name) \(maybeBoss) \(maybePhones)"
  }
  

  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"H") {
    (from) in
    return try Human(name:from.dech(), phones:from.dechArray() as! [Phone], boss:from.dechRef() as? Human)
  }
  override func typeKey() -> String { return Human.typeCode }
  override func encode(to:HierEncoder) {
    // SKIPPED super.encode(to:to)  // Walker super also enchs members we hardcode, so we just ench the members we care about
    to.ench(name)
    to.ench(phones)
    to.enchRef(boss)
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
      let creaturesDecoded = (try? from.dechArray()) ?? [HierCodable]()
      return Zoo(creatures:creaturesDecoded as! [BaseBeast])
    }
  func typeKey() -> String { return Zoo.typeCode }
  func encode(to:HierEncoder) {
    to.ench(creatures)
  }
}


//: ---- Demo of encoding and decoding working ----

// Create Zoo
let phb = Human(name:"PHB")
let startZoo = Zoo(creatures: [
  Flyer(name:"Kookaburra", maxAltitude:5000),
  BaseBeast(name:"Rock"),
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  phb,
  Human(name:"Geek", phones:[Phone(number:555111222, os:.Android), Phone(number:666)], boss:phb)
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

// prove we can encode and decode again
print("\n\nRepeating the Encode/Decode to show still works after retrieved")
let bin2Data = SimpleHierBinaryEncoder().encode(decodedZoo!)
let decodedZoo2:Zoo? = try SimpleHierBinaryDecoder(decodeFrom:bin2Data).decode()
decodedZoo2?.dump()
// prove the backref did correctly link objects
(decodedZoo2?.creatures[4]  as! Human) === (decodedZoo2?.creatures[5] as! Human).boss

