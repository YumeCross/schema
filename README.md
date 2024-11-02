# Schema

Schema library provides APIs to parse Schema and to validate Json by parsed Schema.

## Usages

What is JSON Schema?

> [JSON Schema is the vocabulary that enables JSON data consistency, validity, and interoperability at scale.](https://json-schema.org/)

### Parse

Use `@lib.parse` to parse a JSON Schema.

## Validate

You can use `@lib.validate` to validate a JSON object by a parsed Schema.

### TODO

1. Support for references is being done.
2. Using options to control some validation behavior is in planning.
3. Add documentation.

## Examples

```moonbit
let schema = @lib.parse!({
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

println(schema.validate({ "limited_number": 23 }).is_ok()) // output: true
println(schema.validate({ "limited_number": 42.1 }).is_ok()) // output: false
```

> [!note]
> **The library is WIP!**
> **The APIs are unstable and the functionality is not complete.**
