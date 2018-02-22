import Foundation

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
  func encode(to:HierEncoder)
}

// Generic reusable stuff you just need once
public protocol HierDecoder {
  func read() -> String
  func read() -> Int
  func read() -> Bool
  func read<T>() -> [T]
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
    typedObjects.forEach {
      write($0)
    }
    popContext()
  }
}



public typealias DecoderFactory = (inout HierDecoder) throws -> HierCodable

// one point to register and maintain list of factories
public class HierCodableFactories {
  private static var factories = Dictionary<String, DecoderFactory>()
  public static func Register(key:String, from factory:@escaping DecoderFactory) -> String
  {
    factories[key] = factory
    return key
  }
  
}
