import Foundation

enum DecodeError : Error {
  case noKeyForObject
  case noObjectBodyForKey(key:String)
  
}
// TODO expand signatures to all the native types as per UnkeyedEncodingContainer
public protocol HierEncoder {
  func write(_:String)
  func write(_:Int)
  func write(_:Int?)
  func write(_:Bool)
  func write(_:HierCodable)
  func write(_:HierCodable?)
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
  func read() throws -> String
  func read() throws -> Int
  func read() throws -> Int?
  func read() throws -> Bool
  func readObject() throws -> HierCodable
  func readOptionalObject() throws -> HierCodable?  // when we expect an optional
  func readArray() throws -> [HierCodable]
  func pushContext()
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
  
  // unlike optional primitives, for objects we use a default empty typecode
  // individual binary encoders are allowed to implement how they write optional primitives
  public func write(_ typedObject:HierCodable?) {
    if typedObject == nil {
      write("")
    }
    else {
      write(typedObject!)
    }
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
  public func readObject() throws -> HierCodable {
    if let key:String = try? read() {
      pushContext()
      if let factory = HierCodableFactories.factory(key:key) {
        if var ret: HierCodable = try factory(self) {
          popContext()
          return ret
        }
      }
      throw DecodeError.noObjectBodyForKey(key:key)
    }
    throw DecodeError.noKeyForObject
  }
  
  public func readOptionalObject() throws -> HierCodable?  {
    if let key:String = try? read() {
      if key.count == 0 {
        return nil  // validly detected a None optional
      }
      pushContext()
      if let factory = HierCodableFactories.factory(key:key) {
        if var ret: HierCodable = try factory(self) {
          popContext()
          return ret
        }
      }
      throw DecodeError.noObjectBodyForKey(key:key)
    }
    throw DecodeError.noKeyForObject
  }

  // invoked when we know we have a container of eg array items
  // T is probably a base class for a heterogeneous array
  public func readArray() throws -> [HierCodable]  {
    // nested collections start a new container
    pushContext()
    var ret = [HierCodable]()
    if let numToDecode:Int = try? read() {  // match default write which preceds with length
      for _ in 1...numToDecode  { // typecode and nested container for each
        if let obj = try? readObject() {
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
