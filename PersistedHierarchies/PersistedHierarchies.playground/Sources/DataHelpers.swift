import Foundation
// thanks to https://stackoverflow.com/questions/43241845/how-can-i-convert-data-into-types-like-doubles-ints-and-strings-in-swift

public extension String {
  var data: Data { return Data(utf8) }  // just the raw bytes with no length
}

public extension Numeric {
  var data: Data {
    var source = self
    // This will return 1 byte for 8-bit, 2 bytes for 16-bit, 4 bytes for 32-bit and 8 bytes for 64-bit binary integers. For floating point types it will return 4 bytes for single-precision, 8 bytes for double-precision and 16 bytes for extended precision.
    return Data(bytes: &source, count: MemoryLayout<Self>.size)
  }
}

public extension Data {
  var integer: Int {
    return withUnsafeBytes { $0.pointee }
  }
  var int32: Int32 {
    return withUnsafeBytes { $0.pointee }
  }
  var float: Float {
    return withUnsafeBytes { $0.pointee }
  }
  var float80: Float80 {
    return withUnsafeBytes { $0.pointee }
  }
  var double: Double {
    return withUnsafeBytes { $0.pointee }
  }
  var string: String {
    return String(data: self, encoding: .utf8) ?? ""
  }
}

