// Demo of a polymorphic hierarchy of different classes implementing a protocol
// and still being Codable
// This variant uses unkeyed containers so less data is pushed into the encoded form.

import Foundation

protocol BaseBeast  {
  func move() -> String
  func type() -> Int
  var name: String { get }
}

class DumbBeast : BaseBeast, Codable  {
  static let polyType = 0
  func type() -> Int { return DumbBeast.polyType }

  var name:String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
}

class Flyer : BaseBeast, Codable {
  static let polyType = 1
  func type() -> Int { return Flyer.polyType }

  var name:String
  let maxAltitude:Int
  init(name:String, maxAltitude:Int) {
    self.maxAltitude = maxAltitude
    self.name = name
  }
  func move() -> String { return "\(name) Flies up to \(maxAltitude)"}
}


class Walker : BaseBeast, Codable {
  static let polyType = 2
  func type() -> Int { return Walker.polyType }

  var name:String
  let numLegs: Int
  let hasTail: Bool
  init(name:String, legs:Int=4, hasTail:Bool=true) {
    self.numLegs = legs
    self.hasTail = hasTail
    self.name = name
  }
  func move() -> String {
    if numLegs == 0 {
      return "\(name) Wriggles on its belly"
    }
    let maybeWaggle = hasTail ? "wagging its tail" : ""
    return "\(name) Runs on \(numLegs) legs \(maybeWaggle)"
  }
}

// Uses an explicit index we decode first, to select factory function used to decode polymorphic type
// This is in contrast to the current "traditional" method where decoding is attempted and fails for each type
// This pattern of "leading type code" can be used in more general encoding situations, not just with Codable
//: **WARNING** there is one vulnerable practice here - we rely on the BaseBeast types having a typeCode which
//: is a valid index into the arrays `encoders` and `factories`
struct CodableRef : Codable {
  let refTo:BaseBeast  //In C++ would use an operator to transparently cast CodableRef to BaseBeast
  
  typealias EncContainer = UnkeyedEncodingContainer
  typealias DecContainer = UnkeyedDecodingContainer
  typealias BeastEnc = (inout EncContainer, BaseBeast) throws -> ()
  typealias BeastDec = (inout DecContainer) throws -> BaseBeast
  
  static var encoders:[BeastEnc] = [
    {(e, b) in try e.encode(b as! DumbBeast)},
    {(e, b) in try e.encode(b as! Flyer)},
    {(e, b) in try e.encode(b as! Walker)}
  ]
  
  static var factories:[BeastDec] = [
    {(d) in try d.decode(DumbBeast.self)},
    {(d) in try d.decode(Flyer.self)},
    {(d) in try d.decode(Walker.self)}
  ]

  init(refTo:BaseBeast) {
    self.refTo = refTo
  }
  
  init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let typeCode = try container.decode(Int.self)
    self.refTo = try CodableRef.factories[typeCode](&container)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    let typeCode = self.refTo.type()
    try container.encode(typeCode)
    try CodableRef.encoders[typeCode](&container, refTo)
  }
}


struct Zoo : Codable {
  var creatures = [CodableRef]()
  init(creatures:[BaseBeast]) {
    self.creatures = creatures.map {CodableRef(refTo:$0)}
  }
  func dump() {
    creatures.forEach { print($0.refTo.move()) }
  }
}


//: ---- Demo of encoding and decoding working ----
let startZoo = Zoo(creatures: [
  DumbBeast(name:"Rock"),
  Flyer(name:"Kookaburra", maxAltitude:5000),
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  Walker(name:"Geek", legs:2, hasTail:false)
  ])


startZoo.dump()
print("---------\ntesting JSON\n")
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let encData = try encoder.encode(startZoo)
print(String(data:encData, encoding:.utf8)!)
let decodedZoo = try JSONDecoder().decode(Zoo.self, from: encData)

print ("\n------------\nAfter decoding")

decodedZoo.dump()
