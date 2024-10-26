# Schema

Schema library provides APIs to parse Schema and to validate Json by parsed Schema.

## Usages

What is JSON Schema?

[> JSON Schema is the vocabulary that enables JSON data consistency, validity, and interoperability at scale.](https://json-schema.org/)

### Parse

## Examples

```moonbit
let schema = @schema.parse!({
    "$id": "example",
    "type": "object",
    "properties": {
        "limited_number": {
            "type": "number",
            "minimum": 0,
            "maximum": 42
        }
    }
})

println(schema.validate({ "limited_number": 23 })) // output: true
println(schema.validate({ "limited_number": 42.1 })) // output: false
```

> [!note]
> The library is WIP!
> The APIs are unstable and the functionality is not complete.
