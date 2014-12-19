import strutils, math

type
  Point* = tuple[x: int, y: int]

proc newPoint*(x, y: int): ref Point =
  result = new Point
  result.x = x
  result.y = y

proc clone*(self: ref Point): ref Point =
  newPoint(self.x, self.y)

proc copy*(self, other: ref Point) =
  self.x = other.x
  self.y = other.y

proc `$`*(self: ref Point): string =
  "$#,$#" % [$self.x, $self.y]

proc `==`*(self: ref Point, other: ref Point): bool =
  return self.x == other.x and self.y == other.y

proc `-`*(self, other: ref Point): ref Point =
  result.x = self.x - other.x
  result.y = self.y - other.y

proc `+`*(self, other: ref Point): ref Point =
  result.x = self.x + other.x
  result.y = self.y + other.y

proc `*`*(self, other: ref Point): ref Point =
  result.x = self.x * other.x
  result.y = self.y * other.y

proc perp*(self: ref Point): ref Point =
  result.x = -self.y
  result.y = self.x

proc dot*[T](a,b: T): int =
  result += a.x * b.x
  result += a.y * b.y

proc scale*(self: ref Point, f: float): ref Point =
  result.x = round(self.x.float * f)
  result.y = round(self.y.float * f)

proc gradient*(self, other: ref Point): float =
  if self.x != other.x:
    result = float(self.y - other.y) / float(self.x - other.x)
  else:
    result = NaN

proc y_intersect*(self: ref Point, m: float): float =
  result = self.y.float - (m * self.x.float)

# Point helpers
proc compDir*(i, j, k: ref Point): int =
  let a = (k.x - i.x) * (j.y - i.y)
  let b = (j.x - i.x) * (k.y - i.y)
  case a < b:
    of true:
      -1
    of false:
      case a > b:
        of true:
          1
        of false:
          0
