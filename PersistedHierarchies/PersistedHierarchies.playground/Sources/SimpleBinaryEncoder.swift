import Foundation

// first cut ignoring issues of performancecut
// relies on DataHelper for encoding
// relatively compact but unsafe as you have to read everything in the right order
public class SimpleBinaryEncoder : HierEncoder {
  var buffer:Data
  
  // can pass in existing Data to which we append
  public init(encodeTo:Data = Data()) {
    buffer = encodeTo
  }
  
  public func encode(_ topObj:HierCodable) -> Data {
    // write top of tree
    write(topObj)
    return buffer
  }
  
  public func write(_ value:String)  {
    let strData = value.data
    let leadingLen = UInt32(strData.count)
    buffer.append(leadingLen.data)  // stash leading length for easy decoding
    buffer.append(strData)
  }
  
  public func write(_ value:Int)  {
    buffer.append(value.data)
  }
  
  public func write(_ value:Bool)  {
    let asInt:UInt8 = value ? 1 : 0
    buffer.append(asInt.data)
  }

  // pick up default protocols for write HierCodable and [HierCodable]
  
  // don't encode nested contexts
  public func pushContext() {}
  public func popContext() {}
}

