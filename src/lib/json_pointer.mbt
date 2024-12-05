// NOTE: The whole implementation temporarily assumes that the input is valid at now.

///|
pub fn JsonPointer::parse_pointer(str : String) -> JsonPointer {
  let str = str.trim_space()
  if str == "" {
    // raise InvalidPath(src=str)
    panic()
  }
  match str[0] {
    '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
      unsafe_parse_relative_pointer(str)
    _ => unsafe_parse_abosulute_pointer(str)
  }
}

///| @alert unsafe ""
pub fn JsonPointer::unsafe_parse_abosulute_pointer(str : String) -> JsonPointer {
  if str.trim_space() == "" {
    panic()
  }
  let root = match str.index_of("#") {
    -1 => 0
    i => i
  }
  let url = str.substring(end=root)
  AbsolutePointer(id=url, str.substring(start=root).split("/").collect())
}

// @alert unsafe ""
///|
pub fn JsonPointer::unsafe_parse_relative_pointer(str : String) -> JsonPointer {
  if str.trim_space() == "" {
    panic()
  }
  let path = str.split("/")
  let collection = []
  loop path.peek() {
    None => break RelativePointer(collection)
    Some(level) => {
      path.take(1) |> ignore
      match level.to_array() {

      }
      continue path.peek()
    }
  }
}

///|
pub fn resolve_pointer(self : JsonPointer, path : JsonPointer) -> JsonPointer {
  match (self, path) {
    (AbsolutePointer(id~, _), AbsolutePointer(id="", subpath)) =>
      AbsolutePointer(id~, subpath)
    (AbsolutePointer(id=id1, _), AbsolutePointer(id=id2, subpath)) =>
      if id2.starts_with("..") {
        // TODO: Handle ".." in the path
        AbsolutePointer(id=id1 + id2, subpath)
      } else if id2.contains("://") {
        AbsolutePointer(id=id2, subpath)
      } else {
        let i = id1.last_index_of("/")
        AbsolutePointer(id=id1.substring(end=i + 1) + id2, subpath)
      }
    (AbsolutePointer(id~, path), RelativePointer(subpath)) => ...
    (RelativePointer(_), RelativePointer(_)) => ...
    _ => ...
  }
}

///|
pub fn resolve_value(self : JsonPointer, json : Json) -> Json!Error {
  self |> ignore
  match self {
    AbsolutePointer(id=_, path) as pointer => {
      assert_eq!(path[0], "#")
      loop path[:], path.length(), json {
        ["#"], 1, val => break val
        ["#", ..], _, val => continue path[1:], path[1:].length(), val
        [key], 1, val =>
          break val
            .value(key)
            .or_error!(KeyNotFound(key~, path=pointer, src=json, val))
        [key, ..] as p, _, val =>
          continue p[1:],
            p[1:].length(),
            val
            .value(key)
            .or_error!(KeyNotFound(key~, path=pointer, src=json, val))
        _, _, _ => panic()
      }
    }
    RelativePointer(_path) as _pointer => panic()
  }
}

///|
pub impl Show for JsonPointer with output(self : JsonPointer, logger : Logger) -> Unit {
  match self {
    AbsolutePointer(id~, path) => {
      logger.write_string(id)
      logger.write_string(String::concat(path, separator="/"))
    }
    RelativePointer(path) =>
      logger.write_string(String::concat(path, separator="/"))
  }
}

///|
pub fn to_string(self : JsonPointer) -> String {
  let logger = StringBuilder::new()
  Show::output(self, logger)
  logger.to_string()
}
