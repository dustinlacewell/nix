import graphics, sdl

type Display* = object
  surface*: graphics.PSurface
  width*, height*: int32

proc get_event*(self: ref Display, event: var sdl.TEvent): bool =
    result = sdl.pollEvent(addr(event)) == 1

proc newDisplay*(width, height: int32, title: string): ref Display =
  result = new(Display)
  result.width = width
  result.height = height
  result.surface = newScreenSurface(width, height)
  wmSetCaption(title, nil)


