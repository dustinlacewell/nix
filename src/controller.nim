
from src/display import Display

type Controller* = object
  display*: ref Display
  should_close: bool

proc newController*(display: ref Display): ref Controller =
  result = new(Controller)
  result.display = display
  result.should_close = false

proc close*(self: ref Controller) =
  self.should_close = true

proc closing*(self: ref Controller): bool =
  result = self.should_close

