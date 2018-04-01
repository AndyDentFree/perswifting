import Foundation

func ptrToInt<T : AnyObject>(obj : T) -> Int {
  return Int(bitPattern:UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque()))
}


// first cut ignoring issues of performance
// relatively compact but unsafe as you have to read everything in the right order
public class SimpleHierBinaryEncoder : HierEncoder {
  var buffer:BinaryEncoder
  
  public static let PUSH_CONTEXT_SEPARATOR:UInt8 = 254
  public static let POP_CONTEXT_SEPARATOR:UInt8 = 255

  public init() {
    buffer = BinaryEncoder()
  }
  
  public func encode(_ topObj:HierCodable) -> Data {
    // write top of tree
    write(topObj)
    return buffer.asData()
  }
  
  // relies on BinaryEncoder to manage leading length
  public func write(_ value:String)  {
    buffer.encode(value)
  }
  
  public func write(_ value:UInt8)  {
    buffer.encode(value)
  }
  
  public func write(_ value:UInt16)  {
    buffer.encode(value)
  }
  
  public func write(_ value:UInt32)  {
    buffer.encode(value)
  }

  public func write(_ value:Int)  {
    buffer.encode(value)
  }

  public func write(_ value:Int?)  {
    buffer.encode(value)
  }

  public func write(_ value:Bool)  {
    buffer.encode(value)
  }
  
  //TODO add other binary types

  // pick up default protocols for write HierCodable and [HierCodable]
  
  // don't encode nested contexts
  public func pushContext() {
    write(SimpleHierBinaryEncoder.PUSH_CONTEXT_SEPARATOR)
  }
  public func popContext() {
    write(SimpleHierBinaryEncoder.POP_CONTEXT_SEPARATOR)
  }
}

