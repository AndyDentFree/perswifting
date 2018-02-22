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

// protocol so generic used in EncoderUsing can comply
public protocol EncoderSupplier {
  // function signature from JSONEncoder
  func encode<T>(_:T) throws -> Data where T:Encodable
}
extension JSONEncoder : EncoderSupplier {}

public class EncoderUsing<T:EncoderSupplier>: HierEncoder {
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
  
  public init(_ supplier:T) {
    self.supplier = supplier
  }
  
  // mimics the way Codable.encode works - start at the top
  public func encode(_ encoding:HierCodable) throws -> Data {
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
  
  public func pushContext()
  {
    if container != nil {
      containerStack.append(container!)  // new container for each start, typically a chain of them
      container = container?.nestedUnkeyedContainer()
    }
    else {
      container = realEncoder?.unkeyedContainer()
    }
  }
  
  public func popContext()
  {
    container = containerStack.popLast()
  }
  
  public func write(_ value:String) {
    do { try container?.encode(value) } catch  { print("Write \(value) exception \(error)") }
  }
  public func write(_ value:Int) {
    do { try container?.encode(value) } catch  { print("Write \(value) exception \(error)") }
  }
  public func write(_ value:Bool) {
    do { try container?.encode(value) } catch  { print("Write \(value) exception \(error)") }
  }
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
