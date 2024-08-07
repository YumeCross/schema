# Schema

Schema library provides APIs to parse Schema and to validate Json by parsed Schema.

## Examples

```moonbit
let schema = @lib.parse!({
    "$id": "example",
    "type": "object",
    "properties": {
        "limited_number": {
            "type": "integer",
            "minimum": 0,
            "maximum": 42
        }
    }
})
@test.eq!(@lib.validate(schema, {
    "limited_number": 23
}), true) // Validation passed

@test.eq!(@lib.validate(schema, {
    "limited_number": 233
}), false) // Validation failed
```

> [!note]
> The library is WIP!
> The APIs are unstable and the functionality is not complete.
