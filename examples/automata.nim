import random, strutils, colors, graphics, sdl
from graphics import TRect

import src/app, src/scene

type RuleSet = object
  rules: array[8, bool]

proc ruleno(self: ref RuleSet): int =
  var factor = 1
  for i in 0..7:
    if self.rules[i]:
      result = result + factor
    factor = factor * 2

proc rulefor(self: ref RuleSet, a, b, c: bool): bool =
  var index = 0
  if a: index += 4
  if b: index += 2
  if c: index += 1
  result = self.rules[index]

proc setrule(self: ref RuleSet, ruleno: uint8) =
  var factor = 1
  for i in 0..7:
    self.rules[i] = ((factor and ruleno.int) > 0)
    factor = factor * 2
  echo("Rule: " & $ruleno)

proc randomize(self: ref RuleSet) =
  for i in 0..7:
    self.rules[i] = random_bool()

type AutomataScene* = 
  object of Scene
  last_row: cint
  ruleset: ref RuleSet
  ruleno: int
  copySurf: graphics.PSurface

method randomize(self: ref AutomataScene) =
  var color: Color
  for x in 0..self.ctl.display.w-1:
    case random_bool():
      of true:
        color = colWhite
      of false:
        color = colBlack
    self.ctl.display[x, self.last_row] = color

method midpoint(self: ref AutomataScene) =
  var color: Color
  for x in 0..self.ctl.display.w - 1:
    case x == Natural(self.ctl.display.w / 2):
      of true:
        color = colWhite
      of false:
        color = colBlack
    self.ctl.display[x, self.last_row] = color

method enter(self: ref AutomataScene) =
  self.ctl.display.fillSurface(colBlack)
  self.copySurf = newSurface(self.ctl.display.w, self.ctl.display.h - 1)
  if self.ruleset == nil:
    self.ruleset = new(RuleSet)
    self.ruleset.randomize()
  self.ruleno = self.ruleset.ruleno()
  # cache y value of the last pixel row since we'll reuse it 
  self.last_row = (self.ctl.display.h.cint - 1).int32
  self.ctl.display[int32(self.ctl.display.w / 2), self.last_row] = colWhite

method key_down(self: ref AutomataScene, key: TKey, mods: TMod) =
  case key:
    of K_SPACE:
      var automata_scene = new(AutomataScene)
      self.manager.set_scene(automata_scene)
    of K_UP:
      self.randomize()
    of K_LEFT:
      dec(self.ruleno)
      self.ruleset.setrule(uint8(self.ruleno))
      self.randomize()
    of K_RIGHT:
      inc(self.ruleno)
      self.ruleset.setrule(uint8(self.ruleno))
      self.randomize()
    of K_DOWN:
      self.midpoint()
    else: discard
  
method get_left(self: ref AutomataScene, x, y: cint): Color =
  var dx = x - 1
  if dx < 0:
    dx = self.ctl.display.w.int32 - 1
  result = self.ctl.display[dx, y - 1]

method get_mid(self: ref AutomataScene, x, y: cint): Color =
  result = self.ctl.display[x, y - 1]

method get_right(self: ref AutomataScene, x, y: cint): Color =
  var dx = x + 1
  if dx >= self.ctl.display.w:
    dx = 0
  result = self.ctl.display[dx, y - 1]

method draw(self: ref AutomataScene) =
  var dst = (0, 0, self.ctl.display.w.int, int(self.ctl.display.h - 1))
  var src = (0, 1, self.ctl.display.w.int, int(self.ctl.display.h - 1))
  blit(self.copySurf, graphics.TRect(dst),
       self.ctl.display, src)

  dst = graphics.TRect((0, 0, int(self.ctl.display.w), int(self.ctl.display.h - 1)))
  src = graphics.TRect((0, 0, int(self.ctl.display.w), int(self.ctl.display.h - 1)))
  blit(self.ctl.display, dst,
       self.copySurf, src)

  var color: Color
  # # shift all pixels upwards
  # for y in 0..self.ctl.display.h-2:
  #   for x in 0..self.ctl.display.w-1:
  #     # copy the pixel below, up to this one
  #     color = self.ctl.display[x, y + 1]
  #     self.ctl.display[x, y] = color

  # generate random line at bottom
  for x in 0..self.ctl.display.w.int32 - 1:
    var
      left = self.get_left(x, self.last_row) == colWhite
      mid = self.get_mid(x, self.last_row) == colWhite
      right = self.get_right(x, self.last_row) == colWhite
      life = self.ruleset.rulefor(left, mid, right)
    case life:
      of true:
        color = colWhite
      of false:
        color = colBlack
    self.ctl.display[x, self.last_row] = color


    

var automata_scene = new(AutomataScene)
var automata_app = new(App)
automata_app.init(automata_scene, 1200, 800, "Automata Example")
automata_app.run()
