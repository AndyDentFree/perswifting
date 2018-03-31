# PersistedHierarchies
This demo is a contrast to CodableHierarchies. The primary goal is retaining class inheritance, so uses its own simple coding scheme instead of Codable.

See the RicherPersistedHierarchies explanation below for more complex scenarios.

## SimpleHierBinaryEncoder and Decoder

These use a binary coding class mainly copied from Mike Ash's sample which he implemented for Codable.

See the [article](https://www.mikeash.com/pyblog/friday-qa-2017-07-28-a-binary-coder-for-swift.html) or go straight to the [github repository](https://github.com/mikeash/BinaryCoder/tree/887cecd70c070d86f338065f59ed027c13952c83).

I grabbed the internals of his binary encoding and added a little bit of logic on top to use with the Hirarchical encoders.

Note that the term's _class_ and _object_ are used because the main motivator for this work is the sub-classing relationship not being handled by Codable.

However, I also use the term _thing_ because nothing about this requires you be persisting _objects_ - it should work for enums and structs as well. The later examples with references get into using a struct just to prove this point.

## SimpleDebuggingTextEncoder
This just helps with debugging so you can get a dump of what's been persisted, in a kind of YAML nested format.

It indents things and arrays and brackets arrays.

### Sample Run

```
Original Zoo
Kookaburra  Flies up to 5000
Rock Sits there looking stupid
Snake Wriggles on its belly
Doggie Runs on 4 legs waggling its tail
Geek Runs on 2 legs 

Decoded Zoo
Kookaburra  Flies up to 5000
Rock Sits there looking stupid
Snake Wriggles on its belly
Doggie Runs on 4 legs waggling its tail
Geek Runs on 2 legs 


SimpleDebuggingTextEncoder dump

"Zoo":String
  [
    5:Int
    "F":String
      "Kookaburra":String
      5000:Int
    "BB":String
      "Rock":String
    "W":String
      "Snake":String
      0:Int
      true:Bool
    "W":String
      "Doggie":String
      4:Int
      true:Bool
    "W":String
      "Geek":String
      2:Int
      false:Bool
  ]
```


## RicherPersistedHierarchies
To keep the implementation code simpler, rather than enhancing the base playground, this copy was extended when I needed to cope with nesting and optionals. If you're intersted, you can open the package contents and compare `HierCodable.swift` from each.

### Owned Optionals

Optionals have to have a base type but also need flagging. I chose to use a leading UInt8 to indicate the presence of an optional, so they take up a tiny bit more space. 

The method used to flag optional primitives is left up to the individual encoder, see `BinaryEncoder.NONE_OPTIONAL`

For optional things, we already have an external leading typecode string. So, up at the level of `SimpleHierBinaryEncoder` we just store an empty string as the typecode. This works for nested, **owned** things - see the `Walker` class's `pet` in `RicherPersistedHierarchies`.

## RicherPersistedHierarchiesWithBackRefs

Yet another variant, built on top of `RicherPersistedHierarchies` and adding some minor extension to provide backwards references.

### Nested References
Nested references to a previous thing offer a richer design space, depending on if you need to support forward references or only refer to decoded objects. 

Note _offer a richer design space_ implies there's a lot more scope for arguing and subtle bugs!

There are multiple competing forces here, it would be very nice to be able to strategise the entire thing, maybe with generics, but that is a level of abstraction for another day.

#### Backward References - Design Musings
The concept of _forward references_ is a decoding issue - at the time of encoding, all objects in the graph are assumed to exist. If we create all _leaves_ in advance, then whatever complex graph stucture we create later will only be references to objects that have already been decoded. The annoying, and common, case is a mutual reference, so we need some way to go back and fix the first object to point to the second.

It's easy to store a nested object and at the time of storing an object, native Swift offers no distinction between an object we _"own"_ and a previously _standalone_ object to which we now refer.

So even for these _backward_ references, we still need to have some special way to distinguish stashing a reference to a previous object and storing a nested _owned_ object.

Referring to a previously decoded object implies two responsibilities being satisfied:

1. The _target object_ as an object pointer can be retrieved later when decoding one or more objects referring to it.
2. When we decode a reference to an earlier target, we just point to that object rather than expecting a nested object's properties to be in the stream.

If we take that back to a pragmatic view of what can be persisted, we basically need:

1. A way to label the target object as it is persisted, so it it can be found after decoding.
2. A fixup for decoding objects and following references.

Driving this backwards, we don't have to think object-oriented. Remember that the decoder uses a typekey to lookup a factory function which then processes the next information in the stream. We can provide a different kind of factory to pull some magic reference lookup key out rather than decoding a nested object.

Considering from the viewpoint of the _target object_,  somehow when we **encode** it we need it registered as a target, for consumption in either a dependent object decoding or cleanup pass.

In the spirit of this being a _coarse_ and _simple_ approach to coding, what's the easiest way to handle this?

We can't rely on the encoding of the _later_ referrer because the target won't have had its stream location identified.

It turns out, in thinking through the following alternatives, the balancing is between storage overhead and flexibility. In particular, will there be many target objects shared as a proportion of the total object graph? This variation could later be abstracted to allow a choice of different encoding strategies.

Alternative designs:

1. Explicitly label target objects with an extra call at the time they are first saved - awkward but efficient if there is only a small number of targets. Easy to get wrong but the decode logic can catch that - when you decode something that expects to find a target and the target is missing, it will throw.
2. As part of the `HierCodable` protocol, add a _referrers_ object to each. That manages the relationship but adds overhead in storage if we persist an optional reference to the _referrers_ each time..
3. Use a _referrers_ approach in memory but anticipate only a small number of targets. Store a leading typecode that triggers decoding the next object as a target. (Formally, this is a Decorator pattern.)

Decision - use 3. for now.

#### Forward references

This is not too far from the _forward references_ of a general graph - it needs to store the same information but uses it in a _cleanup pass_ after all objects are created.

However, I don't need them for now so won't include in this version of the playground.
	

## JSON On Hold
The JSON experiment was an attempt to reuse the existing JSON encoder/decoders.

Putting it to one side for a bit due to time pressures.

It is kinda working  at which point get 

    Fatal error: 'try!' expression unexpectedly raised an error: 
    Swift.DecodingError.typeMismatch(Swift.String, Swift.DecodingError.Context(codingPath: 
    [Foundation.(_JSONKey in _12768CA107A31EF2DCE034FD75B541C9)(stringValue: "Index 1", intValue: Optional(1))], 
    debugDescription: "Expected to decode String but found an array instead.", underlyingError: nil)):
    
I am fairly certain the problem is that I am explicitly creating new containers whilst decoding, which works as you recurse down into them but leaves the original at the point in the data stream where you created the nested container.

So I need to either get the containers created differently or somehow advance the main context.

