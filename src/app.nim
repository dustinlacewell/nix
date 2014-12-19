import graphics, sdl, tables, strutils
import scene
import controller

type App* = object
  display: graphics.PSurface
  manager: ref SceneManager
  ctl: ref Controller

proc init*(self: ref App,
           first_scene: ref Scene,
           width, height: int32,
           title: string) =

  self.display = newScreenSurface(width, height)
  self.ctl = newController(self.display)
  self.manager = newSceneManager(self.ctl, first_scene)
  wmSetCaption(title, nil)

proc pump(self: ref App) =
  var event: sdl.TEvent
  while sdl.pollEvent(addr(event)) == 1:
    case event.kind:
      of sdl.QUITEV:
        self.ctl.close()
        break
      of sdl.KEYDOWN:
        var e = evKeyboard(addr(event))
        self.ctl.keys[e.keysym.sym] = true
        self.ctl.mods[e.keysym.modifier] = true
        self.manager.scene.key_down(e.keysym.sym, e.keysym.modifier)
      of sdl.KEYUP:
        var e = evKeyboard(addr(event))
        self.ctl.keys[e.keysym.sym] = false
        self.ctl.mods[e.keysym.modifier] = false
      of sdl.MOUSEBUTTONDOWN:
        self.ctl.mouseDown = true
        self.manager.scene.mouse_down(evMouseButton(addr(event)))
      of sdl.MOUSEBUTTONUP:
        self.ctl.mouseDown = false
      of sdl.MOUSEMOTION:
        var e = evMouseMotion(addr(event))
        self.ctl.mouseX = e.x.int
        self.ctl.mouseY = e.y.int
        self.manager.scene.mouse_motion(e)
      else: discard

proc run*(self: ref App) =
  var
    current_time = getTicks()
    old_time = current_time

  while not self.ctl.closing:
    old_time = current_time
    let t = getTicks()
    let dt = t - old_time
    self.pump()
    self.manager.scene.update(t, dt)
    self.manager.scene.draw()
    sdl.updateRect(self.display.s, 0, 0, self.display.w.int32, self.display.h.int32)
  sdl.quit()
