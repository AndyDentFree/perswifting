// Initial Playground - a hierarchy

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
    let maybeWaggle = hasTail ? "waggling its tail" : ""
    return "\(name) Runs on \(numLegs) legs \(maybeWaggle)"
  }
}


struct CodableRef : Codable {
  let typeCode:Int
  let refTo:BaseBeast  //TODO use an operator to transparently cast these to refTo so they act like a SmartPointer
  
  enum CodingKeys : Int, CodingKey {
    case typeCode
    case refTo
    case dumbBeast
    case flyer
    case walker
  }
  
  typealias EncContainer = KeyedEncodingContainer<CodingKeys>
  typealias DecContainer = KeyedDecodingContainer<CodingKeys>
  typealias BeastEnc = (inout EncContainer, BaseBeast) throws -> ()
  typealias BeastDec = (DecContainer) throws -> BaseBeast
  
  static var encoders:[BeastEnc] = [
    {(e, b) in try e.encode(b as! DumbBeast, forKey:.dumbBeast)},
    {(e, b) in try e.encode(b as! Flyer, forKey:.flyer)},
    {(e, b) in try e.encode(b as! Walker, forKey:.walker)}
  ]
  
  static var factories:[BeastDec] = [
    {(d) in try d.decode(DumbBeast.self, forKey:.dumbBeast)},
    {(d) in try d.decode(Flyer.self, forKey:.flyer)},
    {(d) in try d.decode(Walker.self, forKey:.walker)}
  ]

  init(typeCode:Int, refTo:BaseBeast) {
    self.typeCode = typeCode
    self.refTo = refTo
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.typeCode = try container.decode(Int.self, forKey:.typeCode)
    self.refTo = try CodableRef.factories[self.typeCode](container)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.typeCode, forKey:.typeCode)
    try CodableRef.encoders[self.typeCode](&container, refTo)
  }
}


struct Zoo : Codable {
  var creatures = [CodableRef]()
  init(creatures:[BaseBeast]) {
    self.creatures = creatures.map {CodableRef(typeCode:$0.type(), refTo:$0)}
  }
  func dump() {
    creatures.forEach { print($0.refTo.move()) }
  }
}

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
