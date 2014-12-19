import colors, graphics, sdl, strutils

import geom/poly, geom/line, geom/point, controller

proc high*(self: ref Poly): int =
    self[].high

const diamond_bitmap = @[
  0, 0, 0, 1, 1, 0, 0, 0,
  0, 0, 1, 0, 0, 1, 0, 0,
  0, 1, 0, 0, 0, 0, 1, 0,
  1, 0, 0, 0, 0, 0, 0, 1,
  1, 0, 0, 0, 0, 0, 0, 1,
  0, 1, 0, 0, 0, 0, 1, 0,
  0, 0, 1, 0, 0, 1, 0, 0,
  0, 0, 0, 1, 1, 0, 0, 0,
]

const d_size = 8

type
    Diamond* = object of RootObj
        pos*: ref Point
        speed*: int
        step*: int
        s*: graphics.PSurface
        poly*: ref Poly
        line*: ref Line
        ctl*: ref Controller
        state*: ref DiamondState
        garbage*: seq[ref Poly]
        fc: int

    DiamondState* = object of RootObj
        model*: ref Diamond
        last_key*: ref TKey

proc dst_rect*(self: ref Diamond): graphics.TRect =
    let half_s = d_size / 2.0
    return graphics.TRect((int(self.pos.x.float - half_s), int(self.pos.y.float - half_s), int(half_s), int(half_s)))

proc src_rect*(self: ref Diamond): graphics.TRect =
    return graphics.TRect((0, 0, d_size, d_size))

method init*(self: ref DiamondState, model: ref Diamond) = self.model = model

method update*(self: ref DiamondState, t, dt: int) = discard

method draw*(self: ref DiamondState, surf: graphics.PSurface) =
    surf.blit(self.model.dst_rect(), self.model.s, self.model.src_rect())

method pos(self: ref DiamondState): ref Point =
    self.model.pos

method line(self: ref DiamondState): ref Line =
    self.model.line

method keys(self: ref DiamondState): KeyMap =
    self.model.ctl.keys

method mods(self: ref DiamondState): ModMap =
    self.model.ctl.keys

method get_pressed_key(self: ref DiamondState): TKey =
    if self.keys.pressed(K_LEFT.TKey) and self.last_key[] != K_RIGHT:
        result = K_LEFT

    elif self.keys.pressed(K_RIGHT) and self.last_key[] != K_LEFT:
        result = K_RIGHT

    elif self.keys.pressed(K_UP) and self.last_key[] != K_DOWN:
        result = K_UP

    elif self.keys.pressed(K_DOWN) and self.last_key[] != K_UP:
        result = K_DOWN

method get_pos_offset(self: ref DiamondState, pressed_key: TKey, speed: int): ref Point =
    if pressed_key == K_LEFT and self.last_key[] != K_RIGHT:
        result = newPoint(self.pos.x - speed, self.pos.y)

    elif pressed_key == K_RIGHT and self.last_key[] != K_LEFT:
        result = newPoint(self.pos.x + speed, self.pos.y)

    elif pressed_key == K_UP and self.last_key[] != K_DOWN:
        result = newPoint(self.pos.x, self.pos.y - speed)

    elif pressed_key == K_DOWN and self.last_key[] != K_UP:
        result = newPoint(self.pos.x, self.pos.y + speed)

proc newDiamond*(ctl: ref Controller, poly: ref Poly, line: ref Line, speed = 600): ref Diamond =
    let mp = line.midpoint()
    result = new(Diamond)
    result.poly = poly
    result.ctl = ctl
    result.pos = newPoint(mp.x, mp.y)
    result.line = line
    result.speed = 8000 * 2000000
    result.fc = 0
    result.step = 1
    result.s = newSurface(d_size, d_size)
    result.garbage = newSeq[ref Poly]()

proc init*(self: ref Diamond) =
    var c: Color
    for y in 0..d_size - 1:
        for x in 0..d_size - 1:
            case diamond_bitmap[x + (y * d_size)]:
                of 0:
                    c = colBlack
                of 1:
                    c = colRed
                else: discard
            self.s[x, y] = c

proc goto*(self: ref Diamond, t: Transfer) =
    self.pos.x = t.point.x
    self.pos.y = t.point.y
    self.line = t.line

proc set_state*(self: ref Diamond, state: ref DiamondState) =
    state.init(self)
    self.state = state

proc update*(self: ref Diamond, t, dt: int) =
    self.fc += dt
    while self.fc > 0:
        self.fc -= self.speed
        self.state.update(t, dt)
    self.fc = 0

# States

type
    CutState* = object of DiamondState
        lines*: ref Poly
        starting_line*: ref Line

    MoveState* = object of DiamondState

# Cutstate methods

method init*(self: ref CutState, model: ref Diamond) =
    self.model = model
    self.lines = newPoly()
    self.last_key = new TKey
    self.starting_line = self.model.line
    var new_line = newLine(
        newPoint(model.pos.x, model.pos.y),
        newPoint(model.pos.x, model.pos.y))
    self.lines.add(new_line)

method last(self: ref CutState): ref Line =
    if self.lines.len > 0:
        return self.lines[self.lines.high]

proc test_intersects_cut(self: ref CutState, test: ref Line): bool =
    result = false
    for line in self.lines:
        if line != self.last and line.intersects(test):
            result = true

method draw*(self: ref CutState, surf: graphics.PSurface) =
    for line in self.lines:
        surf.drawStipple((x: line.p1.x.int, y: line.p1.y.int), (x: line.p2.x.int, y: line.p2.y.int), colYellow)
    surf.blit(self.model.dst_rect(), self.model.s, self.model.src_rect())

method update*(self: ref CutState, t, dt: int) =
    let pressed_key = self.get_pressed_key()

    if pressed_key == 0:
        return

    let new_pos = self.get_pos_offset(pressed_key, self.model.step)
    if new_pos == self.pos:
        return
    let new_line = newLine(self.last.p2.clone(), new_pos)

    let test_pos = self.get_pos_offset(pressed_key, self.model.step * 5)
    let test_line = newLine(clone(self.last.p2), clone(test_pos))
    if self.test_intersects_cut(test_line):
        return

    let cur_key = self.last_key[]

    if self.model.poly.contains(new_pos):
        self.last_key[] = pressed_key
        self.pos.copy(new_pos)
        if cur_key == self.last_key[]:
            self.last.p2.copy(self.pos)
        else:
            var new_line = newLine(self.last.p2, new_pos)
            new_line.prev = self.last
            self.last.next = new_line
            self.lines.add(new_line)
    else:
        let finish = self.model.poly.intersects(new_line)
        if finish != nil:
            let p = self.model.poly.intersection(new_line)
            if not isNil(p):
                self.last.p2.copy(p)
                let new_state = new(MoveState)

                self.lines = polyFromSlice(self.lines[1..self.lines.high])

                if self.lines.len > 0:
                    var a = self.model.poly.cut(self.lines)
                    var b = self.model.poly.cut(self.lines.inverted)
                    if a.poly.area > b.poly.area:
                        self.model.poly = a.poly
                        self.model.garbage.add(b.poly)
                    else:
                        self.model.poly = b.poly
                        self.model.garbage.add(a.poly)
                    for line in self.model.poly:
                        if line.contains(self.model.pos):
                            self.model.line = line

                    self.model.set_state(new_state)

# MoveState methods

method init*(self: ref MoveState) = discard

method update*(self: ref MoveState, t, dt: int) =
    var new_pos = clone self.pos
    var speed = self.model.step
    var last_key: TKey

    if self.keys.pressed(K_LEFT.TKey):
        new_pos = newPoint(self.pos.x - speed, self.pos.y)
        last_key = K_LEFT

    elif self.keys.pressed(K_RIGHT):
        new_pos = newPoint(self.pos.x + speed, self.pos.y)
        last_key = K_RIGHT

    elif self.keys.pressed(K_UP):
        new_pos = newPoint(self.pos.x, self.pos.y - speed)
        last_key = K_UP

    elif self.keys.pressed(K_DOWN):
        new_pos = newPoint(self.pos.x, self.pos.y + speed)
        last_key = K_DOWN

    if self.model.ctl.mouseDown:
        let inpoly = self.model.poly.contains(newPoint(self.model.ctl.mouseX, self.model.ctl.mouseY))
        echo("mouse pos ($#, $#) in poly: $#" % [$self.model.ctl.mouseX, $self.model.ctl.mouseY, $inpoly])
        echo($self.model.poly[])

    let transfer = self.model.line.check_transfer(new_pos)

    var garbage_collision = false
    for poly in self.model.garbage:
        for line in poly:
            garbage_collision = line.contains(new_pos)
            if garbage_collision:
                break
        if garbage_collision:
            break

    if self.keys.pressed(K_LSHIFT) and self.pos != new_pos and not garbage_collision:
        if self.model.poly.contains(new_pos):
            let new_state = new(CutState)
            new_state.last_key = new(TKey)
            new_state.last_key[] = last_key
            self.model.set_state(new_state)
            return
    self.model.goto(transfer)

