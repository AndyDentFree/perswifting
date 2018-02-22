//: PersistedHierarchies - use class hierarchy which is not trivially Codable
//: See the Codable.Hierarchies folder for an explanation and an alternative
//: **Assume you have to use inheritance** and want to put those types into a heterogenous array of the base type
//: **Note** for flexibility in registration, this string keys for factory lookup rather than integers
//: there are tricks we could use to directly derive a Hashable from the type but would not be safely persistent

import Foundation

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
protocol EncoderSupplier {
  // function signature from JSONEncoder
  func encode<T>(_:T) throws -> Data where T:Encodable
}
extension JSONEncoder : EncoderSupplier {}

class EncoderUsing<T:EncoderSupplier>: HierEncoder {
  let supplier:EncoderSupplier
  var realEncoder:Encoder?
  var containerStack = [UnkeyedEncodingContainer]()
  var container: UnkeyedEncodingContainer? = nil

  typealias EncoderForwarder = (Encoder) -> ()
  // little helper we encode to pull the actual encoder back out for our use
  // we don't want to complicate things by making ourself Encodable
  struct EncoderExtractor : Encodable {
    let forwarder:EncoderForwarder
    
    init(forwarder:@escaping EncoderForwarder) {
      self.forwarder = forwarder
    }
    
    func encode(to encoder:Encoder) {
      forwarder(encoder)
    }
  }
  
  init(_ supplier:T) {
    self.supplier = supplier
  }
  
  // mimics the way Codable.encode works - start at the top
  func encode(_ encoding:HierCodable) throws -> Data {
    let extractor = EncoderExtractor(forwarder:{(enc:Encoder) in
      self.realEncoder = enc  // the heart of the hack - grab this so we can use it in the tree of calls from encoding.encode
      self.pushContext()  // start with a top level in which we write all the objects
      encoding.encode(to: self)  // with a context established now get the HierCodable to encode itself using us
      self.finishedEncoding()
      })
    return try supplier.encode(extractor)  // now we have realEncoder
  }
  
  private func finishedEncoding()
  {
    realEncoder = nil
    container = nil
    containerStack = [UnkeyedEncodingContainer]()
  }
  
  func pushContext()
  {
    if container != nil {
      containerStack.append(container!)  // new container for each start, typically a chain of them
      container = container?.nestedUnkeyedContainer()
    }
    else {
      container = realEncoder?.unkeyedContainer()
    }
  }
  
  func popContext()
  {
    container = containerStack.popLast()
  }

  func write(_ value:String) {
    do { try container?.encode(value) } catch  { print("Write \(value) exception \(error)") }
  }
  func write(_ value:Int) {
    do { try container?.encode(value) } catch  { print("Write \(value) exception \(error)") }
  }
  func write(_ value:Bool) {
    do { try container?.encode(value) } catch  { print("Write \(value) exception \(error)") }
  }
}

// default implementations so all collections of HierCodable can just be written
extension HierEncoder {
  func write(_ typedObject:HierCodable) {
    write(typedObject.typeKey())  // for decoding, code precedes nested context
    pushContext()
    typedObject.encode(to: self)
    popContext()
  }
  func write(_ typedObjects:[HierCodable]) {
    // nested collections start a new container
    pushContext()
    typedObjects.forEach {
      write($0)
    }
    popContext()
  }
}

protocol HierCodable {
  func typeKey() -> String
  func encode(to:HierEncoder)
}


typealias DecoderFactory = (inout HierDecoder) throws -> HierCodable

// one point to register and maintain list of factories
class HierCodableFactories {
  private static var factories = Dictionary<String, DecoderFactory>()
  static func Register(key:String, from factory:@escaping DecoderFactory) -> String
  {
    factories[key] = factory
    return key
  }

}

//:---- Example classes using HierCodable

class BaseBeast : HierCodable {
  let name: String
  init(name:String) { self.name = name }
  func move() -> String { return "\(name) Sits there looking stupid" }
  
  //MARK HierCodable
  private static let typeCode = HierCodableFactories.Register(key:"BB") {
    (from) in return BaseBeast(name:from.read())
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
    (from) in return Flyer(name:from.read(), maxAltitude:from.read())
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
    (from) in return Walker(name:from.read(), legs:from.read(), hasTail:from.read())
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
    (from) in return Zoo(creatures:from.read())
  }
  func typeKey() -> String { return Zoo.typeCode }
  func encode(to:HierEncoder) {
    to.write(typeKey())
    to.write(creatures)
  }
}


//: ---- Demo of encoding and decoding working ----
let startZoo = Zoo(creatures: [
  Flyer(name:"Kookaburra", maxAltitude:5000),
  BaseBeast(name:"Rock") ,
  Walker(name:"Snake", legs:0),
  Walker(name:"Doggie", legs:4),
  Walker(name:"Geek", legs:2, hasTail:false)
  ])

startZoo.dump()

print("---------\ntesting JSON\n")
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let hierEnc = EncoderUsing(encoder)
let encData = try hierEnc.encode(startZoo)
print("\n---------\nencoded JSON\n")
print(String(data:encData, encoding:.utf8)!)

