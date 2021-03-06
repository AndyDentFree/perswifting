import Foundation

import Foundation

// simple textual dump to view how encoding is working, NOT intended to be decoded!
public class SimpleDebuggingTextEncoder : HierEncoder {
  var buffer:String
  var indentLevel:Int = 0
  var indent = ""
  
  public init() {
    buffer = String()
  }
  
  private func updateIndent(by:Int)
  {
    indentLevel += by
    indent = String(repeating:" ", count:2*indentLevel)
  }
  
  private func appendStr(_ str:String) {
    buffer += "\n\(indent)\(str)"
  }
  
  public func encode(_ topObj:HierCodable) -> String {
    // ench top of tree
    ench(topObj)
    return buffer
  }
  
  public func ench(_ value:String)  {
     appendStr("\"\(value)\":String")
  }
  
  public func ench<T>(_ value:T)  {
    appendStr("\(value):\(T.self)")
  }
  
  public func ench<T>(_ value:T?)  {
    if value == nil {
      appendStr("nil optional:\(T.self)")
    } else {
      appendStr("\(value!):\(T.self)")
    }
  }
  
  // pick up default protocols for ench HierCodable

  // override HierCodable? to describe if otional is missing
  public func ench(_ typedObject:HierCodable?) {
    if typedObject == nil {
      appendStr("nil optional HierCodable")
    }
    else {
      ench(typedObject!)
    }
  }
  
  // override [HierCodable] to describe that it's an array
  public func ench(_ typedObjects:[HierCodable]) {
    // nested collections start a new container
    appendStr("[")
    pushContext()
    ench(typedObjects.count)  // leading count in default format
    typedObjects.forEach {
      ench($0)
    }
    popContext()
    appendStr("]")
  }

  public func enchRef(_ typedObject:HierCodable?) {
    if typedObject == nil {
      appendStr("ref to nil optional HierCodable")
    }
    else {
      appendStr("ref to an \(typedObject!.typeKey())")
    }
  }

  public func pushContext() {
    updateIndent(by:1)
  }
  
  public func popContext() {
    updateIndent(by:-1)
  }
}

