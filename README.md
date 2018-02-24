# perswifting
Persistence and wire formats in Swift

May contain multiple explorations in this area.

## Codable

I started this to explore some aspects of Codable as of Swift 4 in particular supporting polymorphic class hierarchies.

See the `CodableHierarchies\README.md` for a detailed explanation of how polymorphic behaviour with protocols can be easily encoded using Codable.

## PersistedHierarchies

See the `PersistedHierarchies\README.md` for a detailed explanation of how this alternative works, using binary encoding and preserving a **class hierarchy.**

Note that it uses a more robust method of registering factories using a string key, as a contrast to the very dangerous approach in `CodableHierarchies` where we save an index and rely on the programmer to get their factory array right with unique indexes for each type!