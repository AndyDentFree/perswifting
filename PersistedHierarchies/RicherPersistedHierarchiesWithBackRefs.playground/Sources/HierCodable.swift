import Foundation

enum DecodeError : Error {
  case noKeyForObject
  case noObjectBodyForKey(key:String)
  case expectedRefTypecodeKey(badKey:String)
}

// TODO expand signatures to all the native types as per UnkeyedEncodingContainer
public protocol HierEncoder {
  func write(_:String)
  func write(_:Int)
  func write(_:Int?)
  func write(_:Bool)
  func write(_:HierCodable)
  func write(_:HierCodable?)
  func writeRef(_:HierCodable?)
  func write(_:[HierCodable])
  func pushContext()
  func popContext()
}

public protocol HierCodable {
  func typeKey() -> String
  func encode(to:HierEncoder)  // writes out the members of the type
  func persistsReference(from:HierCodable)
  func hasPersistentReference() -> Bool
}

// Generic reusable stuff you just need once
public protocol HierDecoder {
  func read() throws -> String
  func read() throws -> Int
  func read() throws -> Int?
  func read() throws -> Bool
  func readObject() throws -> HierCodable
  func readOptionalObject() throws -> HierCodable?  // when we expect an optional
  func readRef() throws -> HierCodable?
  func readArray() throws -> [HierCodable]
  func pushContext()
  func popContext()
  func saveRef(key:Int, target:HierCodable)
  func getRef(key:Int) -> HierCodable
}

// default implementations so all collections of HierCodable can just be written
extension HierEncoder {
  
  public func write(_ typedThing:HierCodable) {
    if typedThing.hasPersistentReference() {
      write(HierCodableFactories.REF_TARGET_TYPECODE)
      let refKey = ptrToInt(obj:typedThing as AnyObject)
      // Debug print ("Wrote a ref target with refKey \(refKey)")
      write(refKey) // just the ref key to find it on decode
    }
    write(typedThing.typeKey())  // for decoding, code precedes nested context
    pushContext()
    typedThing.encode(to: self)
    popContext()
  }
  
  // unlike optional primitives, for objects we use a default empty typecode
  // individual binary encoders are allowed to implement how they write optional primitives
  public func write(_ typedThing:HierCodable?) {
    if typedThing == nil {
      write("")
    }
    else {
      write(typedThing!)
    }
  }
  
  public func writeRef(_ typedThing:HierCodable?) {
    if typedThing == nil {
      write("")  // reference to null object treated like any other missing optional
    }
    else {  // just a typecode as flag followed by the address as unique identifier
      write(HierCodableFactories.REF_TYPECODE)
      let refKey = ptrToInt(obj:typedThing as AnyObject)
      // debug print ("Wrote a ref with refKey \(refKey)")
      write(refKey) // just the ref key to find it on decode
    }
  }
  
  public func write(_ typedThings:[HierCodable]) {
    // nested collections start a new container
    pushContext()
    write(typedThings.count)  // leading count in default format
    typedThings.forEach {
      write($0)
    }
    popContext()
  }
}

extension HierDecoder {
  
  // helper that reads an object and registers it
  private func readAndRegister() throws -> HierCodable {
    let originalId:Int = try read()
    // debug print ("Read a ref target with refKey: \(originalId)")
    let obj:HierCodable = try readObject()  // recurse to read
    saveRef(key:originalId, target:obj)
    return obj
  }
  
  // generic approach - we precede a container context with a typecode
  // has special handling for objects which have references to them
  // as we need to retain a dictionary
  public func readObject() throws -> HierCodable {
    if let key:String = try? read() {
      if key == HierCodableFactories.REF_TARGET_TYPECODE {
        return try readAndRegister()
      }
      pushContext()
      if let factory = HierCodableFactories.factory(key:key) {
        let ret: HierCodable = try factory(self)
        popContext()
        return ret
      }
      throw DecodeError.noObjectBodyForKey(key:key)
    }
    throw DecodeError.noKeyForObject
  }
  
  // typically an owned objedt rather than top-level
  public func readOptionalObject() throws -> HierCodable?  {
    if let key:String = try? read() {
      if key.count == 0 {
        // for debug print ("readOptionalObject got blank key == None")
        return nil  // validly detected a None optional indicated by blank key
      }
      if key == HierCodableFactories.REF_TARGET_TYPECODE {
        return try readAndRegister()
      }
      // for debug print ("readOptionalObject read key \(key)")
      pushContext()
      if let factory = HierCodableFactories.factory(key:key) {
        let ret: HierCodable = try factory(self)
        popContext()
        return ret
      }
      throw DecodeError.noObjectBodyForKey(key:key)
    }
    throw DecodeError.noKeyForObject
  }

  public func readRef() throws -> HierCodable?  {
    if let key:String = try? read() {
      if key.count == 0 {
        // for debug print ("readOptionalObject got blank key == None")
        return nil  // validly detected a None optional indicated by blank key
      }
      if key == HierCodableFactories.REF_TYPECODE {
        let refKey:Int = try read()
        // debug print("Read a ref with refKey \(refKey)")
        return getRef(key:refKey)
      }
      else {
        throw DecodeError.expectedRefTypecodeKey(badKey:key)
      }
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
      if numToDecode == 0 {
        // print("Empty array but that's OK")
        // Note for some reason the loop below caused an error - cannot create a range
      }
      else {
        for _ in 1...numToDecode  { // typecode and nested container for each
          if let obj = try? readObject() {
            ret.append(obj)
          }
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
  public static let REF_TARGET_TYPECODE = "=>"  // constant usable by extensions above
  public static let REF_TYPECODE = "<="  // constant usable by extensions above

  public static func Register(key:String, from factory:@escaping DecoderFactory) -> String
  {
    factories[key] = factory
    return key
  }
  public static func factory(key:String) -> DecoderFactory? {
    return factories[key]
  }
}
