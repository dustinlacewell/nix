import strutils, math

import geom/point, geom/rect

type
  Line* = object
    p1*, p2*: ref Point
    prev*, next*: ref Line
  Transfer* = tuple[line: ref Line, point: ref Point]

proc newLine*(p1, p2: ref Point): ref Line =
  result = new Line
  result.p1 = p1
  result.p2 = p2
  result.prev = nil
  result.next = nil

proc `$`*(self: ref Line): string =
  var
    prev = ""
    next = ""
    p1 = $(self.p1)
    p2 = $(self.p2)

  if self.prev != nil:
    prev = $self.prev.p2
  else:
    prev = "nil"
  if self.next != nil:
    next = $self.next.p1
  else:
    next = "nil"

  "($# to) $# to $# (to $#)" % [prev, p1, p2, next]

proc `$`*(self: seq[ref Line]): string =
  result = "Line:\n"
  for line in self:
    result &= $line & "\n"

proc clone*(self: ref Line): ref Line =
  result = newLine(self.p1.clone(), self.p2.clone())

proc invert*(self: ref Line) =
  let old_p1 = self.p1
  self.p1 = self.p2
  self.p2 = old_p1

  let old_next = self.next
  self.next = self.prev
  self.prev = self.next

proc contains*(self: ref Line, p: ref Point): bool =
  p.x <= max(self.p1.x, self.p2.x) and
    p.x >= min(self.p1.x, self.p2.x) and
    p.y <= max(self.p1.y, self.p2.y) and
    p.y >= min(self.p1.y, self.p2.y)

proc midpoint*(self: ref Line): ref Point =
  result = new Point
  result.x = round(float(self.p1.x + self.p2.x) / 2)
  result.y = round(float(self.p1.y + self.p2.y) / 2)

proc gradient*(self: ref Line): float =
  result = self.p1.gradient(self.p2)

proc intersects*(self, other: ref Line): bool =
  let d1 = compDir(other.p1, other.p2, self.p1)
  let d2 = compDir(other.p1, other.p2, self.p2)
  let d3 = compDir(self.p1, self.p2, other.p1)
  let d4 = compDir(self.p1, self.p2, other.p2)
  (((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and
    ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0))) or
    (d1 == 0 and other.contains(self.p1)) or
    (d2 == 0 and other.contains(self.p2)) or
    (d3 == 0 and self.contains(other.p1)) or
    (d4 == 0 and self.contains(other.p2))

proc intersect_line*(self, other: ref Line): ref Point =
  if other.p1 == other.p2:
      return nil

  var m1 = self.gradient()
  var m2 = other.gradient()

  let mt1 = classify(m1)
  let mt2 = classify(m2)

  if m1 != m2:
    if (mt1 != fcNan and mt2 != fcNan):
      let b1 = self.p1.y_intersect(m1)
      let b2 = other.p1.y_intersect(m2)
      result = new(Point)
      result.x = round((b2 - b1) / (m1 - m2))
      result.y = round((m1 * result.x.float) + b1)
    else:
      if (mt1 == fcNan):
        let b2 = other.p1.y_intersect(m2)
        result = new(Point)
        result.x = self.p1.x
        result.y = round((m2 * result.x.float) + b2)
      elif (mt2 == fcNan):
        let b1 = self.p1.y_intersect(m1)
        result = new(Point)
        result.x = other.p1.x
        result.y = round((m1 * other.p1.x.float) + b1)

proc intersect_seg*(self, other: ref Line): ref Point =
  var p = self.intersect_line(other)

  if isNil(p):
    return p

  var width = self.p2.x - self.p1.x
  var height = self.p2.y - self.p1.y
  var r1 = (x: self.p1.x, y: self.p1.y, width: width, height: height)
  r1.normalize()

  var width2 = other.p2.x - other.p1.x
  var height2 = other.p2.y - other.p1.y
  var r2 = (x: other.p1.x, y: other.p1.y, width: width2, height: height2)
  r2.normalize()

  var tolerance = 1
  if r1.width < tolerance:
    r1.width = tolerance

  if r1.height < tolerance:
    r1.height = tolerance

  if r2.width < tolerance:
    r2.width = tolerance

  if r2.height < tolerance:
    r2.height = tolerance

  let res1 = r1.contains(p)
  let res2 = r2.contains(p)
  if res1 and res2:
    result = p

proc intersect3*(self: ref Line, other: ref Line): ref Point =
  result = new Point
  let da = self.p2 - self.p1
  let db = other.p2 - other.p1
  let dp = self.p1 - other.p1
  let dap = da.perp()
  let denom = dot[ref Point](dap, db)
  let num = dot[ref Point](dap, dp)
  let newp = db.scale(num / denom) + other.p1
  result.x = newp.x
  result.y = newp.y

proc closest*(self: ref Line, p: ref Point): ref Point =
  let a = self.p1
  let b = self.p2
  let a_to_p = newPoint(p.x - a.x, p.y - a.y)
  let a_to_b = newPoint(b.x - a.x, b.y - a.y)
  let atb2 = pow(a_to_b.x.float, 2.0) + pow(a_to_b.y.float, 2.0)
  let atp_dot_atb = a_to_p.x * a_to_b.x + a_to_p.y * a_to_b.y
  var t = atp_dot_atb.float / atb2
  if t < 0.0:
      t = 0.0
  elif t > 1.0:
      t = 1.0
  result = new Point
  result.x = round(a.x.float + a_to_b.x.float * t)
  result.y = round(a.y.float + a_to_b.y.float * t)

proc check_transfer*(self: ref Line, pos: ref Point): Transfer =
  var cur_closest = self.closest(pos)
  var prev_closest = self.prev.closest(pos)
  var next_closest = self.next.closest(pos)

  # echo "cur closest: " & $cur_closest
  # echo "prev closest: " & $prev_closest
  # echo "next closest: " & $next_closest

#  echo("current p1:" & $self.p1)
  if cur_closest == self.p1 and prev_closest != self.p1:
#    echo "Transfering to prev"
    return (line: self.prev, point: prev_closest)
  elif cur_closest == self.p2:
#    echo "Transfering to next"
    return (line: self.next, point: next_closest)
  else:
#    echo "Not Transfering"
    return (line: self, point: cur_closest)


