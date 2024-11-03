// NOTE: The whole implementation temporarily assumes that the input is valid at now.

pub fn JsonPointer::parse_path(str : String) -> JsonPointer {
  let str = str.trim_space()
  if str == "" {
    panic()
  }
  match str[0] {
    '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
      RelativePath(str.split("/").collect())
    _ => unsafe_parse_abosulute_path(str)
  }
}

/// @alert unsafe "Panic if the string is blank"
pub fn JsonPointer::unsafe_parse_abosulute_path(str : String) -> JsonPointer {
  if str.trim_space() == "" {
    panic()
  }
  let root = match str.index_of("#") {
    -1 => 0
    i => i
  }
  let url = str.substring(end=root)
  AbsolutePath(id=url, str.substring(start=root).split("/").collect())
}

pub fn resolve_path(self : JsonPointer, path: JsonPointer) -> JsonPointer {
  match (self, path) {
    (AbsolutePath(id=id, _), AbsolutePath(id="", subpath)) => AbsolutePath(id=id, subpath)
    (AbsolutePath(id=id1, _), AbsolutePath(id=id2, subpath)) => {
      if id2.starts_with("..") {
        // TODO: Handle ".." in the path
        AbsolutePath(id=id1 + id2, subpath)
      } else if id2.contains("://") {
        AbsolutePath(id=id2, subpath)
      } else {
        let i = id1.last_index_of("/")
        AbsolutePath(id=id1.substring(end=i+1) + id2, subpath)
      }
    }
    (RelativePath(_), RelativePath(_)) => panic()
    _ => ...
  }
}

pub fn resolve_value(self : JsonPointer, _json : Json) -> Json {
  self |> ignore
  ...
}

pub impl Show for JsonPointer with output(self : JsonPointer, logger : Logger) -> Unit {
  match self {
    AbsolutePath(~id, path) => {
      logger.write_string(id)
      logger.write_string(String::concat(path, separator="/"))
    }
    RelativePath(path) => {
      logger.write_string(String::concat(path, separator="/"))
    }
  }
}

pub fn to_string(self : JsonPointer) -> String {
  let logger = StringBuilder::new()
  Show::output(self, logger)
  logger.to_string()
}
