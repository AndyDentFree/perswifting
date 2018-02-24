# PersistedHierarchies
This demo is a contrast to CodableHierarchies where it insists on retaining class inheritance, so uses its own simple coding scheme instead of Codable.

## SimpleHierBinaryEncoder and Decoder

These use a binary coding class mainly copied from Mike Ash's sample which he implemented for Codable.

See the [article](https://www.mikeash.com/pyblog/friday-qa-2017-07-28-a-binary-coder-for-swift.html) or go straight to the [github repository](https://github.com/mikeash/BinaryCoder/tree/887cecd70c070d86f338065f59ed027c13952c83).

I grabbed the internals of his binary encoding and added a little bit of logic on top to use with the Hirarchical encoders.

## SimpleDebuggingTextEncoder
This just helps with debugging so you can get a dump of what's been persisted, in a kind of YAML nested format.

It indents objects and arrays and brackets arrays.

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

## JSON On Hold

Putting it to one side for a bit due to time pressures.

It is kinda working  at which point get 

    Fatal error: 'try!' expression unexpectedly raised an error: 
    Swift.DecodingError.typeMismatch(Swift.String, Swift.DecodingError.Context(codingPath: 
    [Foundation.(_JSONKey in _12768CA107A31EF2DCE034FD75B541C9)(stringValue: "Index 1", intValue: Optional(1))], 
    debugDescription: "Expected to decode String but found an array instead.", underlyingError: nil)):
    
I am fairly certain the problem is that I am explicitly creating new containers whilst decoding, which works as you recurse down into them but leaves the original at the point in the data stream where you created the nested container.

So I need to either get the containers created differently or somehow advance the main context.

