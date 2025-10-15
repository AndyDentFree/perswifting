# perswifting
Persistence and wire formats in Swift

May contain multiple explorations in this area.

**Quick Update 2025-10-15** noticing the age of this material, wanted to say it's still valid and a (much-expanded) version of the encoding in PersistedHierarchies is used in the Touchgram platform, for our [interactive messages][t1] and Particles documents in the particle-editing design/dev tool [Purrticles][t2].

## Codable

I started this to explore some aspects of Codable as of Swift 4 in particular supporting polymorphic class hierarchies.

See the `CodableHierarchies\README.md` for a detailed explanation of how polymorphic behaviour with protocols can be easily encoded using Codable.

## PersistedHierarchies

See the `PersistedHierarchies\README.md` for a detailed explanation of how this alternative works, using binary encoding and preserving a **class hierarchy.**

Note that it uses a more robust method of registering factories using a string key, as a contrast to the very dangerous approach in `CodableHierarchies` where we save an index and rely on the programmer to get their factory array right with unique indexes for each type!

There are multiple playgrounds in there exploring increasing features through to backward references.

[t1]: https://www.touchgram.com/
[t2]: https://www.touchgram.com/purrticles
