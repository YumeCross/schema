# Schema

Schema library provides APIs to parse Schema and to validate Json by parsed Schema.

**The module `lib` is out of date. Please use `lib2` instead. And after the parsing is done, `lib2` will take place of the original `lib` completely.**

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

println(schema.validate({ "limited_number": 23 }).is_ok()) // output: true
println(schema.validate({ "limited_number": 42.1 }).is_ok()) // output: false
```

> [!note]
> **The library is WIP!**
> **The APIs are unstable and the functionality is not complete.**
