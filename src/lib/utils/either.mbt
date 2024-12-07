///|
pub impl[L : Compare, R : Compare] Compare for Either[L, R] with compare(
  self,
  other
) {
  match (self, other) {
    (Left(l1), Left(l2)) => l1.compare(l2)
    (Right(r1), Right(r2)) => r1.compare(r2)
    _ => panic()
  }
}

///|
pub fn is_left[L, R](self : Either[L, R]) -> Bool {
  match self {
    Left(_) => true
    Right(_) => false
  }
}

///|
pub fn is_right[L, R](self : Either[L, R]) -> Bool {
  match self {
    Left(_) => false
    Right(_) => true
  }
}

///|
pub fn left[L, R](self : Either[L, R]) -> L? {
  match self {
    Left(l) => Some(l)
    Right(_) => None
  }
}

///|
pub fn right[L, R](self : Either[L, R]) -> R? {
  match self {
    Left(_) => None
    Right(r) => Some(r)
  }
}

///|
pub fn flip[L, R](self : Either[L, R]) -> Either[R, L] {
  match self {
    Left(l) => Right(l)
    Right(r) => Left(r)
  }
}

///|
pub fn map_left[L1, L2, R](
  self : Either[L1, R],
  f : (L1) -> L2
) -> Either[L2, R] {
  match self {
    Left(l) => Left(f(l))
    Right(r) => Right(r)
  }
}

///|
pub fn map_right[L, R1, R2](
  self : Either[L, R1],
  f : (R1) -> R2
) -> Either[L, R2] {
  match self {
    Left(l) => Left(l)
    Right(r) => Right(f(r))
  }
}

///|
pub fn map_either[L1, L2, R1, R2](
  self : Either[L1, R1],
  f : (L1) -> L2,
  g : (R1) -> R2
) -> Either[L2, R2] {
  match self {
    Left(l) => Left(f(l))
    Right(r) => Right(g(r))
  }
}

///|
pub fn either[L, R, T](self : Either[L, R], f : (L) -> T, g : (R) -> T) -> T {
  match self {
    Left(l) => f(l)
    Right(r) => g(r)
  }
}

///|
pub fn and_then[L, R, T](
  self : Either[L, R],
  f : (R) -> Either[L, T]
) -> Either[L, T] {
  match self {
    Left(l) => Left(l)
    Right(r) => f(r)
  }
}
