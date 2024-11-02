# Schema

Schema library provides APIs to parse Schema and to validate Json by parsed Schema.

<<<<<<< HEAD
## Usages

What is JSON Schema?

[> JSON Schema is the vocabulary that enables JSON data consistency, validity, and interoperability at scale.](https://json-schema.org/)

### Parse
=======
**The module `lib` is out of date. Please use `lib2` instead. And after the parsing is done, `lib2` will take place of the original `lib` completely.**
>>>>>>> ff8ee500a3edc35b9d1b5ff703b0783342fcb235

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
