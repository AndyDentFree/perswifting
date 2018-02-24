import Foundation

// relatively compact but unsafe as you have to read everything in the right order
public class SimpleHierBinaryDecoder : HierDecoder {
  var buffer:BinaryDecoder

  public init(decodeFrom:Data) {
    buffer = BinaryDecoder(data:decodeFrom)
  }

  public func decode<T>() throws -> T?  {
    return try readObject() as? T
  }

  public func read() throws -> String {
    return try buffer.decode()
  }

  public func read() throws -> Int {
    return try buffer.decode()
  }

  public func read() throws -> UInt8 {
    return try buffer.decode()
  }

  public func read() throws -> UInt16 {
    return try buffer.decode()
  }

  public func read() throws -> UInt32 {
    return try buffer.decode()
  }

  public func read() throws -> UInt64 {
    return try buffer.decode()
  }

  public func read() throws -> Bool {
    return try buffer.decode()
  }

  // pick up default protocols for read HierCodable and [HierCodable]
/*  func readObject() -> HierCodable?
  func readArray() -> [HierCodable]
*/
  // don't encode nested contexts
  public func pushContext() {
    if let sep:UInt8 = try? read() {
      if sep != 254 {
        print("Error - expected pushContext separator but read \(sep)")
      }
    }
  }
  
  public func popContext() {
    if let sep:UInt8 = try? read() {
      if sep != 255 {
        print("Error - expected pushContext separator but read \(sep)")
      }
    }
  }
}
