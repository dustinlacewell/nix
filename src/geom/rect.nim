import geom/point


type
  Rect* = tuple[x, y, width, height: int]

proc normalize*(self: var Rect) =
  if self.width < 0:
    self.x += self.width
    self.width = -self.width

  if self.height < 0:
    self.y += self.height
    self.height = -self.height

proc contains*(self: Rect, p: ref Point): bool =
  p.x >= self.x and p.x < self.x + self.width and p.y >= self.y and p.y < self.y + self.height