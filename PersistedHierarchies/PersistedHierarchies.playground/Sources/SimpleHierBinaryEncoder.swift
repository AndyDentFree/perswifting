import Foundation
import CoreGraphics  // for CGFloat

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
  
  public func encode(_ topObj:HierCodable) -> [UInt8] {
    // ench top of tree
    ench(topObj)
    return buffer.encodedData()
  }

  public func encoded() -> [UInt8] {
    return buffer.encodedData()
  }
  
  // relies on BinaryEncoder to manage leading length
  public func ench(_ value:String)  {
    buffer.encode(value)
  }
  
  public func ench(_ value:UInt8)  {
    buffer.encode(value)
  }
  
  public func ench(_ value:UInt16)  {
    buffer.encode(value)
  }
  
  public func ench(_ value:UInt32)  {
    buffer.encode(value)
  }

  public func ench(_ value:UInt64)  {
    buffer.encode(value)
  }

  public func ench(_ value:Int)  {
    buffer.encode(value)
  }
  
  public func ench(_ value:Float32)  {
    buffer.encode(value)
  }

  public func ench(_ value:Float64)  {
    buffer.encode(value)
  }

  public func ench(_ value:CGFloat)  {
    buffer.encode(Float64(value))
  }

  public func ench(_ value:Bool)  {
    buffer.encode(value)
  }
  //TODO add other binary types

  // pick up default protocols for ench HierCodable and [HierCodable]
  
  // don't encode nested contexts
  public func pushContext() {
    ench(SimpleHierBinaryEncoder.PUSH_CONTEXT_SEPARATOR)
  }
  public func popContext() {
    ench(SimpleHierBinaryEncoder.POP_CONTEXT_SEPARATOR)
  }
}

