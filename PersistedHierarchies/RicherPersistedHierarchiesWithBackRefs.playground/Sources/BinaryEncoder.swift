import Foundation
// Portions copied From Mike Ash's BinaryCoder
// Uses https://developer.apple.com/documentation/corefoundation/byte_order_utilities
// Prefer LittleEndian format on wire as will usually be a null macro
// Prefixes strings with a UInt16 and Data with a UInt32
// Prefixes optionals with a UInt8 flag
public class BinaryEncoder {
  fileprivate var data: [UInt8] = []
  
  public init() {}
  public func encodedData() -> [UInt8] { return data }
  public func asData() -> Data {
      return Data(data)
  }
}


/// Methods for decoding various types.
public extension BinaryEncoder {
  public static let HAS_OPTIONAL:UInt8 = 0xF
  static let NONE_OPTIONAL:UInt8 = 0
  static let NONE_OPTIONAL_AS_LEN16:UInt16 = 0xFFFF

  func encode(_ value: Bool)  {
    let asNum:UInt8 = value ? 1 : 0
    data.append(asNum)
  }
  
  func encode(_ value: Float) {
    appendBytes(of: CFConvertFloatHostToSwapped(value))
  }
  
  func encode(_ value: Double) {
    appendBytes(of: CFConvertDoubleHostToSwapped(value))
  }
  
  func encode(_ value: UInt8) {
    data.append(value)
  }
  
  func encode(_ value: UInt16) {
    appendBytes(of: CFSwapInt16HostToLittle(value))
  }

  func encode(_ value: UInt32) {
    appendBytes(of: CFSwapInt32HostToLittle(value))
  }
  
  func encode(_ value: UInt64) {
    appendBytes(of: CFSwapInt64HostToLittle(value))
  }
  
  func encode(_ value: Int) {
    appendBytes(of: CFSwapInt64HostToLittle(UInt64(value)))
  }
  
  func encode(_ value: Int?) {
    if value == nil {
      appendBytes(of:BinaryEncoder.NONE_OPTIONAL)
    } else {
      appendBytes(of:BinaryEncoder.HAS_OPTIONAL)
      appendBytes(of: CFSwapInt64HostToLittle(UInt64(value!)))
    }
  }

  func encode(_ value: String) {
    let len:UInt16 = UInt16(value.count)
    encode(len)
    data += Array(value.utf8) as [UInt8]
  }

  /// hides the flag for missing optional inside the length word
  func encode(_ value: String?) {
    if value == nil {
        appendBytes(of:BinaryEncoder.NONE_OPTIONAL_AS_LEN16)
    } else {
        encode(value!)
    }
  }
  
  func encode(_ value: Data) {
    let len:UInt32 = UInt32(value.count)
    encode(len)
    data.append(contentsOf:value)
  }
  
}
  
/// Internal method for encoding raw data.
private extension BinaryEncoder {
  /// Append the raw bytes of the parameter to the encoder's data. No byte-swapping
  /// or other encoding is done. Expect the caller to do swaps.
  func appendBytes<T>(of: T) {
    var target = of
    withUnsafeBytes(of: &target) {
      data.append(contentsOf: $0)
    }
  }
}

