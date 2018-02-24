import Foundation

// Unlike the typical Decoder approach, we don't require a separate init(from:) but instead
// HierDecodable classes register a factory function

// protocol so generic used in DecoderUsing can comply
public protocol  DecoderSupplier {
  // function signature from JSONDecoder
  func decode<T>(_:T.Type, from: Data) throws -> T where T:Decodable
}
extension JSONDecoder : DecoderSupplier {}  // once-off so we can be used with JSONDecoder

// instances are created by a decode call
public class DecoderUsing: HierDecoder, Decodable {
  var realDecoder:Decoder?
  var containerStack = [UnkeyedDecodingContainer]()
  var container: UnkeyedDecodingContainer? = nil
  var topDecoded:HierCodable? = nil
  
  public func topObject() -> HierCodable? { return topDecoded}
  
  // mimics the way Codable.decode works - start at the top
  // the big difference is we get the type codes FIRST so we can invoke a factory
  // this is invoked by JSONDecoder to create our instance - we decode and hang onto topDecoded
  public required init(from: Decoder)  {
    self.realDecoder = from  // the heart of the hack - grab this so we can use it in the tree of calls from decode
    self.pushContext()  // start with a top level container, recurse down doing all the decoding
    topDecoded = try? readObject()  // with a context established now
    self.finishedDecoding()
  }
  
  private func finishedDecoding()
  {
    realDecoder = nil
    container = nil
    containerStack = [UnkeyedDecodingContainer]()
  }
  
  //TODO more robust error handling
  public func pushContext()
  {
    if container != nil {
      containerStack.append(container!)  // new container for each start, typically a chain of them
      try! container = container?.nestedUnkeyedContainer()
    }
    else {
      try! container = realDecoder?.unkeyedContainer()
    }
  }
  
  public func popContext()
  {
    container = containerStack.popLast()
  }
  
  public func contextCount() -> Int?
  {
    return container?.count
  }

  // TODO expand signatures to all the native types as per UnkeyedDecodingContainer
  // TODO better error handling!
  public func read() throws -> String {
      return try! container!.decode(String.self)
  }
  
  public func read() throws -> Int {
    return try! container!.decode(Int.self)
  }
  
  public func read() throws -> Bool {
    return try! container!.decode(Bool.self)
  }
}
