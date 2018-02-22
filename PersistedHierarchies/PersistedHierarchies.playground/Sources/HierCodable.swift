import Foundation

// TODO expand signatures to all the native types as per UnkeyedEncodingContainer
public protocol HierEncoder {
  func write(_:String)
  func write(_:Int)
  func write(_:Bool)
  func write(_:HierCodable)
  func write(_:[HierCodable])
  func pushContext()
  func popContext()
}

public protocol HierCodable {
  func typeKey() -> String
  func encode(to:HierEncoder)  // writes out the members of the type
}

// Generic reusable stuff you just need once
public protocol HierDecoder {
  func read() -> String
  func read() -> Int
  func read() -> Bool
  func readObject() -> HierCodable?
  func readArray() -> [HierCodable]
  func pushContext()
  func contextCount() -> Int?
  func popContext()
}


// default implementations so all collections of HierCodable can just be written
extension HierEncoder {
  public func write(_ typedObject:HierCodable) {
    write(typedObject.typeKey())  // for decoding, code precedes nested context
    pushContext()
    typedObject.encode(to: self)
    popContext()
  }
  public func write(_ typedObjects:[HierCodable]) {
    // nested collections start a new container
    pushContext()
    write(typedObjects.count)  // leading count in default format
    typedObjects.forEach {
      write($0)
    }
    popContext()
  }
}

extension HierDecoder {
  // generic approach - we precede a container context with a typecode
  public func readObject() -> HierCodable? {
    var ret: HierCodable? = nil
    let key:String = read()
    if key.count > 0 {
      pushContext()
      if let factory = HierCodableFactories.factory(key:key) {
        ret = try? factory(self)
      }
      popContext()
    }
    return ret
  }
  
  // invoked when we know we have a container of eg array items
  // T is probably a base class for a heterogeneous array
  public func readArray() -> [HierCodable]  {
    // nested collections start a new container
    pushContext()
    var ret = [HierCodable]()
    if let numToDecode = contextCount() {
      print("reading \(numToDecode) objects")
      for _ in 1...numToDecode/2  { // typecode and nested container for each
        if let obj = readObject() {
          ret.append(obj)
        }
      }
    }
    popContext()
    return ret
  }
}



public typealias DecoderFactory = (HierDecoder) throws -> HierCodable

// one point to register and maintain list of factories
public class HierCodableFactories {
  private static var factories = Dictionary<String, DecoderFactory>()
  public static func Register(key:String, from factory:@escaping DecoderFactory) -> String
  {
    factories[key] = factory
    return key
  }
  public static func factory(key:String) -> DecoderFactory? {
    return factories[key]
  }
}
