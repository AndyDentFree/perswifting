//: PersistedHierarchies - use class hierarchy which is not trivially Codable
//: See the Codable.Hierarchies folder for an explanation and an alternative
//: **Assume you have to use inheritance** and want to put those types into a heterogenous array of the base type

import Cocoa

// Generic reusable stuff you just need once
protocol HierDecoder {
  func read() -> String
  func read() -> Int
  func read() -> Bool
  func read<T>() -> [T]
}

protocol HierEncoder {
  func write(_:String)
  func write(_:Int)
  func write(_:Bool)
  func write(_:HierCodable)
  func write(_:[HierCodable])
  func pushContext()
  func popContext()
}

// protocol so generic used in EncoderUsing can comply
protocol UnkeyedContainerSupplier {
  func unkeyedContainer() -> UnkeyedEncodingContainer
}
extension JSONEncoder : UnkeyedContainerSupplier {}

class EncoderUsing<T:UnkeyedContainerSupplier>: HierEncoder {
  let realEncoder:T
  var containerStack = [UnkeyedEncodingContainer]()
  lazy var container: UnkeyedEncodingContainer? = nil
  
  init(_ enc:T) {
    realEncoder = enc
    pushContext()  // start with a top level in which we write all the objects
  }
  
  func pushContext()
  {
    if container != nil {
      containerStack.append(container!)  // new container for each start, typically a chain of them
    }
    container = realEncoder.unkeyedContainer()
  }
  
  func popContext()
  {
    container = containerStack.popLast()
  }

  func write(_ value:String) {
    try! container?.encode(value)
  }
  func write(_ value:Int) {
    try! container?.encode(value)
  }
  func write(_ value:Bool) {
    try! container?.encode(value)
  }
}

// default implementations so all collections of HierCodable can just be written
extension HierEncoder {
  func write(_ typedObject:HierCodable) {
    write(typedObject.type())
    typedObject.encode(to: self)
  }
  func write(_ typedObjects:[HierCodable]) {
    // nested collections should start a new container
    pushContext()
    typedObjects.forEach {  // same as $0.write()
      write($0.type())
      $0.encode(to: self)
    }
    popContext()
  }
}

protocol HierCodable {
  func type() -> Int
  func encode(to:HierEncoder)
}

typealias DecoderFactory = (inout HierDecoder) throws -> HierCodable

// one point to register and maintain list of factories
class HierCodableFactories {
  private static var Factories = [DecoderFactory]()
  static func Register(decodesType:Int, from factory:@escaping DecoderFactory) -> Int
  {
    Factories[decodesType] = factory
    return decodesType
  }

}

//:---- Example classes using HierCodable

class BaseBeast : HierCodable {
  let name: String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
  
  //MARK HierCodable
  private static let typeCode:Int = HierCodableFactories.Register(decodesType:0) {
    (from) in return BaseBeast(name:from.read())
  }
  func type() -> Int { return BaseBeast.typeCode }
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
  private static let typeCode = HierCodableFactories.Register(decodesType:1) {
    (from) in return Flyer(name:from.read(), maxAltitude:from.read())
  }
  override func type() -> Int { return Flyer.typeCode }
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
  private static let typeCode = HierCodableFactories.Register(decodesType:1) {
    (from) in return Walker(name:from.read(), legs:from.read(), hasTail:from.read())
  }
  override func type() -> Int { return Walker.typeCode }
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
  private static let typeCode:Int = HierCodableFactories.Register(decodesType:4) {
    (from) in return Zoo(creatures:from.read())
  }
  func type() -> Int { return Zoo.typeCode }
  func encode(to:HierEncoder) {
    // write zoo typecode here????????
    to.write(creatures)
  }
}


//: ---- Demo of encoding and decoding working ----
let startZoo = Zoo(creatures: [
  Flyer(name:"Kookaburra", maxAltitude:5000),
  BaseBeast(name:"Rock"),
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  Walker(name:"Geek", legs:2, hasTail:false)
  ])

startZoo.dump()

print("---------\ntesting JSON\n")
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let hierEnc = EncoderUsing(encoder)
startZoo.encode(to:hierEnc)
//let encData = try encoder.encode(startZoo)
//print(String(data:encData, encoding:.utf8)!)

