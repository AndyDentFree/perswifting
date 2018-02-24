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
    // write top of tree
    write(topObj)
    return buffer
  }
  
  public func write(_ value:String)  {
     appendStr("\"\(value)\":String")
  }
  
  public func write<T>(_ value:T)  {
    appendStr("\(value):\(T.self)")
  }
  
  //TODO add other binary types
  
  // pick up default protocols for write HierCodable
  // override [HierCodable] to describe that it's an array
  public func write(_ typedObjects:[HierCodable]) {
    // nested collections start a new container
    appendStr("[")
    pushContext()
    write(typedObjects.count)  // leading count in default format
    typedObjects.forEach {
      write($0)
    }
    popContext()
    appendStr("]")
  }

  public func pushContext() {
    updateIndent(by:1)
  }
  
  public func popContext() {
    updateIndent(by:-1)
  }
}

