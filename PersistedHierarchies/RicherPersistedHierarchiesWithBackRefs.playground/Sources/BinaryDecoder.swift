import Foundation
// Portions copied From Mike Ash's BinaryCoder
// Uses https://developer.apple.com/documentation/corefoundation/byte_order_utilities
// Prefer LittleEndian format on wire as will usually be a null macro
// Prefixes strings with a UInt16 and Data with a UInt32

public class BinaryDecoder {
  fileprivate let data: [UInt8]
  fileprivate var cursor = 0
  
  public init(data: [UInt8]) {
    self.data = data
  }
  
  public init(data: Data) {
    self.data = Array(data)
  }
  public func encodedData() -> [UInt8] { return data }  // mostly for debugging
}


/// The error type.
public extension BinaryDecoder {
  /// All errors which `BinaryDecoder` itself can throw.
  enum Error: Swift.Error {
    /// The decoder hit the end of the data while the values it was decoding expected
    /// more.
    case prematureEndOfData
    
    /// Attempted to decode a type which is `Decodable`, but not `BinaryDecodable`. (We
    /// require `BinaryDecodable` because `BinaryDecoder` doesn't support full keyed
    /// coding functionality.)
    case typeNotConformingToBinaryDecodable(Decodable.Type)
    
    /// Attempted to decode a type which is not `Decodable`.
    case typeNotConformingToDecodable(Any.Type)
    
    /// Attempted to decode an `Int` which can't be represented. This happens in 32-bit
    /// code when the stored `Int` doesn't fit into 32 bits.
    case intOutOfRange(Int64)
    
    /// Attempted to decode a `UInt` which can't be represented. This happens in 32-bit
    /// code when the stored `UInt` doesn't fit into 32 bits.
    case uintOutOfRange(UInt64)
    
    /// Attempted to decode a `Bool` where the byte representing it was not a `1` or a
    /// `0`.
    case boolOutOfRange(UInt8)
    
    /// Attempted to decode a `String` but the encoded `String` data was not valid
    /// UTF-8.
    case invalidUTF8([UInt8])
  }
}


/// Methods for decoding various types.
public extension BinaryDecoder {

  // UNLIKE C++ we get overload matching on return types!
  func decode() throws -> Float {
    var swapped = CFSwappedFloat32()
    try read(into: &swapped)
    return CFConvertFloatSwappedToHost(swapped)
  }
  
  func decode() throws -> Double {
    var swapped = CFSwappedFloat64()
    try read(into: &swapped)
    return CFConvertDoubleSwappedToHost(swapped)
  }
  
  func decode() throws -> Bool {
    var oneByte:UInt8 = 0
    try read(into: &oneByte)
    return oneByte == 1
  }
  
  func decode() throws -> UInt8 {
    var oneByte:UInt8 = 0
    try read(into: &oneByte)
    return oneByte
  }

  func decode() throws -> UInt16 {
    var swapped:UInt16 = 0
    try read(into: &swapped)
    return CFSwapInt16LittleToHost(swapped)
  }
  
  func decode() throws -> UInt32 {
    var swapped:UInt32 = 0
    try read(into: &swapped)
    return CFSwapInt32LittleToHost(swapped)
  }
  
  func decode() throws -> UInt64 {
    var swapped:UInt64 = 0
    try read(into: &swapped)
    return CFSwapInt64LittleToHost(swapped)
  }
  
  func decode() throws -> Int {
    var swapped:UInt64 = 0
    try read(into: &swapped)
    return Int(CFSwapInt64LittleToHost(swapped))
  }
  
  func decode() throws -> Int? {
    if try !hasOptional() {
      return nil
    }
    let ret:Int = try decode()
    return ret
  }
  
  private func decodeStringOfLen(_ len: UInt16) throws -> String {
    if len == 0 {  // OK, we use them as typecodes for optional objects
      return ""
    }
    let strData = try readData(byteCount:Int(len))
    return String(data:strData, encoding:.utf8) ?? ""
  }

  func decode() throws -> String {
    let len:UInt16 = try decode()
    return try decodeStringOfLen(len)
  }
  
  /// bit of a hack use the leading length to indicate optional
  func decode() throws -> String? {
    let len:UInt16 = try decode()
    if len == BinaryEncoder.NONE_OPTIONAL_AS_LEN16 {
      return nil
    }
    return try decodeStringOfLen(len)
  }
  
  func decode() throws -> Data {
    let len:UInt32 = try decode()
    if len == 0 {
      print ("Empty Data encoded")
      return Data()
    }
    return try readData(byteCount:Int(len))
  }
}


/// Internal methods for decoding raw data.
private extension BinaryDecoder {
  /// Read the given number of bytes into the given pointer, advancing the cursor
  /// appropriately.
  func read(_ byteCount: Int, into: UnsafeMutableRawPointer) throws {
    if cursor + byteCount > data.count {
      throw Error.prematureEndOfData
    }
    
    data.withUnsafeBytes({
      let from = $0.baseAddress! + cursor
      memcpy(into, from, byteCount)
    })
    
    cursor += byteCount
  }
  
  /// Return a Data which might be used to load a sstring or image
  func readData(byteCount: Int) throws  -> Data{
    if cursor + byteCount > data.count {
      throw Error.prematureEndOfData
    }
    
    var ret = Data()
    data.withUnsafeBytes({
      let from = $0.baseAddress! + cursor
      ret = Data(bytes:from, count:byteCount)
    })
    cursor += byteCount
    return ret
  }
  
  
  /// Read the appropriate number of raw bytes directly into the given value. No byte
  /// swapping or other postprocessing is done.
  func read<T>(into: inout T) throws {
    try read(MemoryLayout<T>.size, into: &into)
  }

  
  private func hasOptional() throws -> Bool {
    var oneByte:UInt8 = 0
    try read(into: &oneByte)
    return oneByte == BinaryEncoder.HAS_OPTIONAL
  }
}

