import graphics, tables, sdl

from src/display import Display

type KeyMap* = Table[TKey, bool]

proc pressed*(self: KeyMap, key: TKey): bool =
    if not self.hasKey(key):
        return false
    return self[key]

type ModMap* = Table[TMod, bool]

# proc pressed*(self: ModMap, key: TMod): bool =
#     if not self.hasKey(key):
#         return false
#     return self[key]

type Controller* = object
  display*: graphics.PSurface
  should_close: bool
  keys*: KeyMap
  mods*: ModMap
  mouseX*, mouseY*: int
  mouseDown*: bool

proc newController*(display: graphics.PSurface): ref Controller =
  result = new(Controller)
  result.display = display
  result.should_close = false
  result.keys = initTable[Tkey, bool]()
  result.mods = initTable[TMod, bool]()

proc close*(self: ref Controller) =
  self.should_close = true

proc closing*(self: ref Controller): bool =
  result = self.should_close

