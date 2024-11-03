// NOTE: The whole implementation temporarily assumes that the input is valid at now.

pub fn JsonPointer::parse_path(str : String) -> JsonPointer {
  // TODO: Implement relative path parsing
  JsonPointer::parse_abosulute_path(str)
}

pub fn JsonPointer::parse_abosulute_path(str : String) -> JsonPointer {
  let root = match str.index_of("#") {
    -1 => 0
    i => i
  }
  let url = match str.substring(end=root) {
    "" => []
    url => [url.substring(end=root)]
  }
  [..url, ..str.substring(start=root).split("/")]
}

pub fn resolve(_self : JsonPointer, _base : JsonPointer) -> JsonPointer {
  ...
}

pub impl Show for JsonPointer with output(self : JsonPointer, logger : Logger) -> Unit {
  logger.write_string(if self._[0] == "#" { "#/" } else { self._[0] })
  logger.write_string(
    String::concat(self._[1:].iter().collect(), separator="/"),
  )
}

pub fn to_string(self : JsonPointer) -> String {
  let logger = StringBuilder::new()
  Show::output(self, logger)
  logger.to_string()
}
