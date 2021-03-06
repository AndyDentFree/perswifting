import Foundation
import CoreGraphics  // for CGFloat

enum DecodeError : Error {
    case decodingBaseClassShouldBeOverridden
    case unableToDecode
    case noKeyForObject
    case noObjectBodyForKey(key:String)
}
    
// TODO expand signatures to all the native types as per UnkeyedEncodingContainer
public protocol HierEncoder {
    func ench(_: String)
    func ench(_: Int)
    func ench(_: Int?)
    func ench(_: UInt8)
    func ench(_: UInt16)
    func ench(_: UInt32)
    func ench(_: UInt64)
    func ench(_: Float32)
    func ench(_: Float64)
    func ench(_: CGFloat)
    func ench(_: Bool)
    func ench(_: HierCodable)
    func ench(_: HierCodable?)
    func ench(_: [HierCodable])
    func pushContext()
    func popContext()
}

public protocol HierCodable {
    func typeKey() -> String
    func encode(to: HierEncoder)  // encodes the properties of the type, not its typeKey
}

// Generic reusable stuff you just need once
public protocol HierDecoder {
    func dech() throws -> String
    func dech() throws -> Int
    func dech() throws -> Int?
    func dech() throws -> UInt8
    func dech() throws -> UInt16
    func dech() throws -> UInt32
    func dech() throws -> UInt64
    func dech() throws -> Float32
    func dech() throws -> Float64
    func dech() throws -> CGFloat
    func dech() throws -> Bool
    func dechObject() throws -> HierCodable
    func dechOptionalObject() throws -> HierCodable?    // when we expect an optional
    func dechArray() throws -> [HierCodable]
    func pushContext()
    func popContext()
}


// default implementations so all collections of HierCodable can just be written
extension HierEncoder {
    public func ench(_ typedThing:HierCodable) {
        ench(typedThing.typeKey())  // for decoding, code precedes nested context
        pushContext()
        typedThing.encode(to: self)
        popContext()
    }
    
    // unlike optional primitives, for objects we use a default empty typecode
    // individual binary encoders are allowed to implement how they ench optional primitives
    public func ench(_ typedThing:HierCodable?) {
        if typedThing == nil {
            ench("")
        }
        else {
            ench(typedThing!)
        }
    }
    
    public func ench(_ typedThings: [HierCodable]) {
        // nested collections start a new container
        pushContext()
        ench(typedThings.count)  // leading count in default format
        typedThings.forEach {
            ench($0)
        }
        popContext()
    }
}

extension HierDecoder {
    // generic approach - we precede a container context with a typecode
    public func dechObject() throws -> HierCodable {
        if let key:String = try? dech() {
            pushContext()
            if let factory = HierCodableFactories.factory(key:key) {
                let ret: HierCodable = try factory(self)
                popContext()
                return ret
            }
            throw DecodeError.noObjectBodyForKey(key:key)
        }
        throw DecodeError.noKeyForObject
    }
    
    // typically an owned object rather than top-level
    public func dechOptionalObject() throws -> HierCodable?  {
        if let key:String = try? dech() {
            if key.count == 0 {
                // for debug print ("dechOptionalObject got blank key == None")
                return nil  // validly detected a None optional indicated by blank key
            }
            // for debug print ("dechOptionalObject dech key \(key)")
            pushContext()
            if let factory = HierCodableFactories.factory(key:key) {
                let ret: HierCodable = try factory(self)
                popContext()
                return ret
            }
            throw DecodeError.noObjectBodyForKey(key:key)
        }
        throw DecodeError.noKeyForObject
    }

    // invoked when we know we have a container of eg array items
    // T is probably a base class for a heterogeneous array
    public func dechArray() throws -> [HierCodable]  {
        // nested collections start a new container
        pushContext()
        var ret = [HierCodable]()
        if let numToDecode: Int = try? dech() {  // match default ench which precedes with length
            if numToDecode == 0 {
                // print("Empty array but that's OK")
                // Note for some reason the loop below caused an error - cannot create a range
            }
            else {
                for _ in 1...numToDecode    { // typecode and nested container for each
                    if let obj = try? dechObject() {
                        ret.append(obj)
                    }
                }
            }
        }
        popContext()
        return ret
    }
}


public typealias DecoderFactory = (HierDecoder) throws -> HierCodable

// one point to register and maintain list of factories
public class HierCodableFactories {
    private static var factories = Dictionary<String, DecoderFactory>()
    public static func Register(key:String, from factory:@escaping DecoderFactory) -> String
    {
        factories[key] = factory
        return key
    }

    public static func factory(key: String) -> DecoderFactory? {
        return factories[key]
    }
}
