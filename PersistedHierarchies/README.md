# PersistedHierarchies
This demo is a contrast to CodableHierarchies where it insists on retaining class inheritance, so uses its own simple coding scheme instead of Codable.

## JSON On Hold

Putting it to one side for a bit due to time pressures.

It is kinda working  at which point get 

    Fatal error: 'try!' expression unexpectedly raised an error: 
    Swift.DecodingError.typeMismatch(Swift.String, Swift.DecodingError.Context(codingPath: 
    [Foundation.(_JSONKey in _12768CA107A31EF2DCE034FD75B541C9)(stringValue: "Index 1", intValue: Optional(1))], 
    debugDescription: "Expected to decode String but found an array instead.", underlyingError: nil)):
    
I am fairly certain the problem is that I am explicitly creating new containers whilst decoding, which works as you recurse down into them but leaves the original at the point in the data stream where you created the nested container.

So I need to either get the containers created differently or somehow advance the main context.

## Roll-your own
Rather than working on EncoderUsing to wrap the JSONEncoder et al (which is fine, it's just the DecoderUsing which needs work), I'm going to do my own encoding in order to just ship something ASAP.

