import Foundation
import CoreGraphics  // for CGFloat

// relatively compact but unsafe as you have to dech everything in the right order
public class SimpleHierBinaryDecoder : HierDecoder {
  var buffer:BinaryDecoder
  private var refTargets = Dictionary<Int, HierCodable>()
  
  public init(decodeFrom:Data) {
    buffer = BinaryDecoder(data:decodeFrom)
  }

  public init(decodeFrom:[UInt8]) {
    buffer = BinaryDecoder(data:decodeFrom)
  }

  public func decode<T>() throws -> T?  {
    return try dechObject() as? T
  }

  public func dech() throws -> String {
    return try buffer.decode()
  }

  public func dech() throws -> String? {
    return try buffer.decode()
  }

  public func dech() throws -> Int {
    return try buffer.decode()
  }

  public func dech() throws -> Int? {
    return try buffer.decode()
  }

  public func dech() throws -> UInt8 {
    return try buffer.decode()
  }

  public func dech() throws -> UInt16 {
    return try buffer.decode()
  }

  public func dech() throws -> UInt32 {
    return try buffer.decode()
  }

  public func dech() throws -> UInt64 {
    return try buffer.decode()
  }

  public func dech() throws -> Float32 {
    return try buffer.decode()
  }

  public func dech() throws -> Float64 {
    return try buffer.decode()
  }

  public func dech() throws -> CGFloat {
    if let ret:Float64 = try? buffer.decode() {
      return CGFloat(ret)
    }
    return 0
  }

  public func dech() throws -> Bool {
    return try buffer.decode()
  }

  // pick up default protocols for dech HierCodable and [HierCodable]

  // don't encode nested contexts
  public func pushContext() {
    if let sep:UInt8 = try? dech() {
      if sep != SimpleHierBinaryEncoder.PUSH_CONTEXT_SEPARATOR {
        print("Error - expected pushContext separator but dech \(sep)")
      }
    }
  }
  
  public func popContext() {
    if let sep:UInt8 = try? dech() {
      if sep != SimpleHierBinaryEncoder.POP_CONTEXT_SEPARATOR {
        print("Error - expected popContext separator but dech \(sep)")
      }
    }
  }

  public func saveRef(key:Int, target:HierCodable)
  {
    refTargets[key] = target
  }
  
  public func getRef(key:Int) -> HierCodable {
    return refTargets[key]!
  }

}
