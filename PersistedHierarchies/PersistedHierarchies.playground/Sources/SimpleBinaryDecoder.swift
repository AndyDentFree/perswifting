import Foundation

// relies on DataHelper for decoding
// relatively compact but unsafe as you have to read everything in the right order
public class SimpleBinaryDecoder : HierDecoder {
  var buffer:Data
  var bufPtr:UnsafePointer<UInt8>
  
  /*var index:Data.Index
  
  public init(decodeFrom:Data, fromIndex:Data.Index = 0) {
    buffer = decodeFrom
    index = fromIndex
  }
   */
  public init(decodeFrom:Data) {
    buffer = decodeFrom
    bufPtr = buffer.withUnsafeBytes {$0.pointee}
  }

  public func decode<T>() -> T?  {
    return readObject() as? T
  }
  /*
  public func read() -> String {
    let rawPtr = UnsafeRawPointer(bufPtr)
    let leadingLen  = Int(rawPtr.load(as: UInt32.self))
    bufPtr = bufPtr.advanced(by:MemoryLayout<UInt32>.size)
    let ret = String(bytesNoCopy:UnsafeMutableRawPointer(mutating:bufPtr), length:leadingLen, encoding:.utf8, freeWhenDone:false)
    bufPtr = bufPtr.advanced(by:leadingLen)
    return ret ?? ""
  }*/

  public func read() -> String {
    let rawPtr = UnsafeRawPointer(bufPtr)
    let leadingLen  = Int(rawPtr.load(as: UInt32.self))
    //let strData = Data(bytes:UnsafeRawPointer(bufPtr), count:leadingLen)
    //bufPtr = bufPtr.advanced(by:leadingLen)
    //return strData.string
    return "Zoo"
  }

  public func read() -> Int {
    let rawPtr = UnsafeRawPointer(bufPtr)
    let ret : Int = rawPtr.load(as: Int.self)
    bufPtr = bufPtr.advanced(by:MemoryLayout<Int>.size)
    return ret
  }
  
  public func read() -> Bool {
    let flagByte:UInt8 = bufPtr.pointee
    bufPtr = bufPtr.advanced(by:1)
    return flagByte == 1
  }

  // pick up default protocols for write HierCodable and [HierCodable]
/*  func readObject() -> HierCodable?
  func readArray() -> [HierCodable]
*/
  // don't encode nested contexts
  public func pushContext() {}
  public func popContext() {}
  public func contextCount() -> Int? {
    return nil
  }
}
