// Class which lets you reuse any Encoder you like
// You need to add to your code an extension to add conformance, eg:
// extension JSONEncoder : EncoderSupplier {}

import Foundation

// protocol so generic used in EncoderUsing can comply
public protocol  EncoderSupplier {
  // function signature from JSONEncoder
  func encode<T>(_:T) throws -> Data where T:Encodable
}
extension JSONEncoder : EncoderSupplier {}  // once-off so we can be used with JSONEncoder

public class EncoderUsing<SupplierT:EncoderSupplier>: HierEncoder {
  let supplier:EncoderSupplier
  var realEncoder:Encoder?
  var containerStack = [UnkeyedEncodingContainer]()
  var container: UnkeyedEncodingContainer? = nil
  
  typealias EncoderForwarder = (Encoder) -> ()
  
  // little helper we encode to pull the actual encoder back out for our use
  // we don't want to complicate things by making ourself Encodable
  // This is necessary because you can't directly use JSONEncoder as an Encoder - it SUPPLIES one.
  struct EncoderExtractor : Encodable {
    let forwarder:EncoderForwarder
    
    init(forwarder:@escaping EncoderForwarder) {
      self.forwarder = forwarder
    }
    
    func encode(to encoder:Encoder) {
      forwarder(encoder)
    }
  }
  
  public init(_ supplier:SupplierT) {
    self.supplier = supplier
  }
  
  // mimics the way Codable.encode works - start at the top
  public func encode(_ topObject:HierCodable) throws -> Data {
    let extractor = EncoderExtractor(forwarder:{(enc:Encoder) in
      self.realEncoder = enc  // the heart of the hack - grab this so we can use it in the tree of calls from encoding.encode
      self.pushContext()  // start with a top level in which we write all the objects
      self.write(topObject)
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
  
  // TODO expand signatures to all the native types as per UnkeyedEncodingContainer
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
