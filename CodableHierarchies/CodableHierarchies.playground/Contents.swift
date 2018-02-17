// Initial Playground - a hierarchy

import Foundation

protocol BaseBeast  {
  func move() -> String
  func type() -> Int
  var name: String { get }
}

class DumbBeast : BaseBeast, Codable  {
  static let polyType = 0
  var name:String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
  func type() -> Int { return DumbBeast.polyType }
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
  
  typealias Factory = (Decoder) -> BaseBeast
 /* static var factories:[Factory] = [
  {(d) in return d.decode(DumbBeast.self, forKey:.dumbBeast)}
    
  ]*/
  typealias EncContainer = KeyedEncodingContainer<CodingKeys>
  static var encDumb = { (enc:inout EncContainer, beast:BaseBeast) in try enc.encode(beast as! DumbBeast, forKey:.dumbBeast) }
  typealias DecContainer = KeyedDecodingContainer<CodingKeys>
  static var decDumb = { (dec:DecContainer) in try dec.decode(DumbBeast.self, forKey:.dumbBeast) }

  init(typeCode:Int, refTo:BaseBeast) {
    self.typeCode = typeCode
    self.refTo = refTo
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.typeCode = try container.decode(Int.self, forKey:.typeCode)
    self.refTo = try CodableRef.decDumb(container) //try container.decode(DumbBeast.self, forKey:.dumbBeast)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.typeCode, forKey:.typeCode)
    try CodableRef.encDumb(&container, refTo)
    //var container = encoder.unkeyedContainer()
    // encode a DumbBeast
    ///try container.encode(self.typeCode)
    
    // the encode method is generic on a Codable type so reports an   error: CodableHierarchies.playground:50:13: error: ambiguous reference to member 'encode(_:forKey:)'
    // if we attempt to just encode the parent types
    // try container.encode(self.refTo, forKey:.dumbBeast)
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
  DumbBeast(name:"Rock")/*,
  Flyer(name:"Kookaburra", maxAltitude:5000),
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  Walker(name:"Geek", legs:2, hasTail:false)*/
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
