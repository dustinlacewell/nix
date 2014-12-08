import graphics, sdl

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
        self.manager.scene.key_down(e.keysym.sym, e.keysym.modifier)
      of sdl.MOUSEBUTTONDOWN:
        self.manager.scene.mouse_down(evMouseButton(addr(event)))
      of sdl.MOUSEMOTION:
        self.manager.scene.mouse_motion(evMouseMotion(addr(event)))
      else: discard

proc run*(self: ref App) =
  while not self.ctl.closing:
    self.pump()
    self.manager.scene.update()
    self.manager.scene.draw()
    sdl.updateRect(self.display.s, 0, 0, self.display.w.int32, self.display.h.int32)
  sdl.quit()
