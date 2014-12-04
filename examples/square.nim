import sdl, graphics, colors

from src/app import App, init, run
import src/scene, src/controller

type WindowScene = object of Scene

method key_down(self: ref WindowScene, key: TKey, mods: TMod) =
  case key:
    of sdl.K_ESCAPE:
      self.ctl.close()
    else: discard

method draw(self: ref WindowScene) =
  self.ctl.display.surface.fillRect((50, 50, 100, 100), colFuchsia)

var window_scene = new(WindowScene)
var window_app = new(App)
window_app.init(window_scene, 200, 200, "Window Example")
window_app.run()
