//: PersistedHierarchies - use class hierarchy which is not trivially Codable
//: See the Codable.Hierarchies folder for an explanation and an alternative
//: **Assume you have to use inheritance** and want to put those types into a heterogenous array of the base type
//: **Note** for flexibility in registration, this string keys for factory lookup rather than integers
//: there are tricks we could use to directly derive a Hashable from the type but would not be safely persistent

import Foundation


//:---- Example classes using HierCodable

class BaseBeast : HierCodable {
  let name: String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
  
  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"BB") {
    (from) in
    print("in BaseBeast factory")
    return BaseBeast(name:from.read())
  }
  func typeKey() -> String { return BaseBeast.typeCode }
  func encode(to:HierEncoder) {
    to.write(name)
  }
}

class Flyer : BaseBeast {
  let maxAltitude:Int
  init(name:String, maxAltitude:Int) {
    self.maxAltitude = maxAltitude
    super.init(name: name)
  }
  override func move() -> String { return "\(name)  Flies up to \(maxAltitude)"}

  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"F") {
    (from) in
      print("in Flyer factory")
      return Flyer(name:from.read(), maxAltitude:from.read())
  }
  override func typeKey() -> String { return Flyer.typeCode }
  override func encode(to:HierEncoder) {
    super.encode(to:to)
    to.write(maxAltitude)
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
    print("in Walker factory")
    return Walker(name:from.read(), legs:from.read(), hasTail:from.read())
  }
  override func typeKey() -> String { return Walker.typeCode }
  override func encode(to:HierEncoder) {
    super.encode(to:to)
    to.write(numLegs)
    to.write(hasTail)
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
      print("in Zoo factory")
      return Zoo(creatures:from.readArray() as! [BaseBeast])
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
  //BaseBeast(name:"Rock"),
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  Walker(name:"Geek", legs:2, hasTail:false)
  ])
print("Original Zoo")
startZoo.dump()

//: ---- Using a simple encoder
let binData = SimpleBinaryEncoder().encode(startZoo)
let dec = SimpleBinaryDecoder(decodeFrom:binData)
let decodedZoo:Zoo? = dec.decode()
decodedZoo?.dump()

//let dump = binData.reduce(String()) {(str, b) in str + String(format: "%02x", b)}

//: ---- Using JSON Encoder
/*
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let hierEnc = EncoderUsing(encoder)
let encData = try hierEnc.encode(startZoo)
print("\n---------\nencoded JSON\n")
print(String(data:encData, encoding:.utf8)!)

print("\n---------\nDecoding\n")
let hierDecoder = try JSONDecoder().decode(DecoderUsing.self, from: encData)
let decodedZoo = hierDecoder.topObject() as! Zoo

print("Decoded zoo")
decodedZoo.dump()
*/
