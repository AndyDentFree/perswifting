import Foundation

// first cut ignoring issues of performancecut
// relies on DataHelper for encoding
// relatively compact but unsafe as you have to read everything in the right order
public class SimpleHierBinaryEncoder : HierEncoder {
  var buffer:BinaryEncoder
  
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
  
  public func write(_ value:Bool)  {
    buffer.encode(value)
  }
  //TODO add other binary types

  // pick up default protocols for write HierCodable and [HierCodable]
  
  // don't encode nested contexts
  public func pushContext() {
    write(UInt8(254))
  }
  public func popContext() {
    write(UInt8(255))
  }
}

