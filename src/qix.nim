import graphics, colors, math, strutils, sdl, algorithm
from graphics import TRect

import app, scene, controller, geom/poly, geom/point, diamond

type WindowScene = object of Scene
  p: ref Diamond
  poly: ref Poly

method enter(self: ref WindowScene) =
  let a = newPoint(0, 0)
  let b = newPoint(self.ctl.display.w - 1, 0)
  let c = newPoint(self.ctl.display.w - 1, self.ctl.display.h - 1)
  let d = newPoint(0, self.ctl.display.h - 1)
  var poly = newPoly([a, b, c, d])

  var state = new(MoveState)
  self.p = newDiamond(self.ctl, poly, poly[0])
  self.p.init()
  self.p.set_state(state)

method update(self: ref WindowScene, t, dt: int) =
  if t mod 5 == 0:
    self.p.update(t, dt)

method draw(self: ref WindowScene) =
  self.ctl.display.fillRect(graphics.TRect((0, 0, self.ctl.display.w, self.ctl.display.h)), colBlack)
  var count = 0
  for i in 0..self.p.garbage.high:
    count += 1
    let poly = self.p.garbage[i]
    if poly != self.p.poly:
      poly.draw(self.ctl.display, filled=true)
  self.p.poly.draw(self.ctl.display, filled=false)
  self.p.state.draw(self.ctl.display)

var window_scene = new(WindowScene)
var window_app = new(App)
window_app.init(window_scene, 500, 500, "Window Example")
window_app.run()
