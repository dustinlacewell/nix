import graphics, sdl

import display
import scene
import controller

type App* = object
  ctl: ref Controller
  manager: ref SceneManager

proc init*(self: ref App, 
           first_scene: ref Scene, 
           width, height: int32,
           title: string) =
  
  var display = newDisplay(width, height, title)
  self.ctl = newController(display)
  self.manager = newSceneManager(self.ctl, first_scene)

proc pump(self: ref App) =
  var event: sdl.TEvent
  while self.ctl.display.get_event(event):
    var eventp = addr(event)
    case event.kind:
      of sdl.QUITEV:
        self.ctl.close()
        break
      of sdl.KEYDOWN:
        var e = evKeyboard(eventp)
        self.manager.scene.key_down(e.keysym.sym, e.keysym.modifier)
      of sdl.MOUSEBUTTONDOWN:
        self.manager.scene.mouse_down(evMouseButton(eventp))
      of sdl.MOUSEMOTION:
        self.manager.scene.mouse_motion(evMouseMotion(eventp))
      else: discard

proc run*(self: ref App) =
  while not self.ctl.closing:
    self.pump()
    self.manager.scene.update()
    self.manager.scene.draw()
    sdl.updateRect(self.ctl.display.surface.s, 0, 0, self.ctl.display.width, self.ctl.display.height)
  sdl.quit()
