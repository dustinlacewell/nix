import graphics

from src/display import Display

type Controller* = object
  display*: graphics.PSurface
  should_close: bool

proc newController*(display: graphics.PSurface): ref Controller =
  result = new(Controller)
  result.display = display
  result.should_close = false

proc close*(self: ref Controller) =
  self.should_close = true

proc closing*(self: ref Controller): bool =
  result = self.should_close

