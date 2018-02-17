# CodableHierarchies
This demo goes into one way supporting polymorphic class hierarchies using protocols to replace inheritance.

There are two problems.

1. You cannot use Codable directly on classes in a hierarchy - Swift requires you to manually implement `init(from:)` and `encode(to:)` even if all the properties in your classes are otherwise Codable.
2. Swift, **by design** does not support heterogenous arrays. If you have an array of a base class, it will not allow you to encode and decode to get back instances of subclasses.

The `CodeableHierarchies.playground` demonstrates an alternative approach.

Polymorphic behaviour is provided by having classes implement a base protocol and `Codable`.

A trivial wrapper struct `CodableRef` is used in an array to provide the smart encoding and decoding using a type code.

The usual approach for encoding and decoding a varying type is to **try** decoding and then fall through to try another variant.

Using an integer type that acts as an index to factory functions is faster at the cost of being a little more vulnerable to coding errors.

Note that both keyed and unkeyed containers are shown so you can see the JSON difference.

See `CodableHierarchiesUnkeyed.playground` as the simpler form.

### Unkeyed JSON

```
{
  "creatures" : [
    [
      0,
      {
        "name" : "Rock"
      }
    ],
    [
      1,
      {
        "name" : "Kookaburra",
        "maxAltitude" : 5000
      }
    ],
    [
      2,
      {
        "name" : "Snake",
        "numLegs" : 0,
        "hasTail" : true
      }
    ],
    [
      2,
      {
        "name" : "Doggie",
        "numLegs" : 4,
        "hasTail" : true
      }
    ],
    [
      2,
      {
        "name" : "Geek",
        "numLegs" : 2,
        "hasTail" : false
      }
    ]
  ]
}

```

### Keyed JSON

```
{
  "creatures" : [
    {
      "typeCode" : 0,
      "dumbBeast" : {
        "name" : "Rock"
      }
    },
    {
      "flyer" : {
        "name" : "Kookaburra",
        "maxAltitude" : 5000
      },
      "typeCode" : 1
    },
    {
      "typeCode" : 2,
      "walker" : {
        "name" : "Snake",
        "numLegs" : 0,
        "hasTail" : true
      }
    },
    {
      "typeCode" : 2,
      "walker" : {
        "name" : "Doggie",
        "numLegs" : 4,
        "hasTail" : true
      }
    },
    {
      "typeCode" : 2,
      "walker" : {
        "name" : "Geek",
        "numLegs" : 2,
        "hasTail" : false
      }
    }
  ]
}
```
