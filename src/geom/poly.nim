import graphics, sdl, colors, sdl_gfx, algorithm

import geom/line, geom/point

type
  Poly* = seq[ref Line]

proc high*(self: ref Poly): int =
    self[].high

proc len*(self: ref Poly): int =
    self[].len

proc add*(self: ref Poly, x: ref Line) =
    self[].add(x)

iterator items*(self: ref Poly): ref Line {.inline.} =
    for line in self[]:
        yield line

iterator enumerate*(self: ref Poly): tuple[idx: int, line: ref Line] {.inline.} =
    for i in 0..self.high:
        yield (idx: i, line: self[i])

proc newPoly*(points: varargs[ref Point]): ref Poly =
    result = new(Poly)
    result[] = newSeq[ref Line]()

    if points.len == 0:
        return

    for i in 0..(points.high - 1):
        result.add(newLine(
            clone(points[i]),
            clone(points[i+1]),
        ))
    result.add(newLine(
        clone(points[points.high]),
        clone(points[0]),
    ))

    for i in 1..points.high - 1:
        result[i].next = result[i+1]
        result[i].prev = result[i-1]

    let high_i = points.high
    result[0].prev = result[high_i]
    result[0].next = result[1]
    result[high_i].prev = result[high_i - 1]
    result[high_i].next = result[0]

proc polyFromSlice*(s: seq[ref Line]): ref Poly =
    result = newPoly()
    for line in s:
        result.add(line)

proc `$`*(self: ref Poly): string =
    result = "Poly:\n"
    for line in self:
        result &= $line & "\n"

proc contains*(self: ref Poly, p: ref Point): bool =
    let px = p.x.float
    let py = p.y.float
    var X = newSeq[float]()
    var Y = newSeq[float]()
    for line in self:
        X.add(line.p1.x.float)
        Y.add(line.p1.y.float)

    let sides = len(X)
    var j = sides - 1
    for i in 0..sides - 1:
        if (Y[i] < py and Y[j] >= py) or (Y[j] < py and Y[i] >= py):
            if X[i] + (py - Y[i]) / (Y[j] - Y[i]) * (X[j] - X[i]) < px:
                result = not result
        j = i

proc intersects*(self: ref Poly, line: ref Line): ref Line =
  for edge in self:
    if line.intersects(edge):
      return edge

proc intersection*(self: ref Poly, line: ref Line): ref Point =
  for edge in self:
    let p = line.intersect_seg(edge)
    if not isNil(p):
      return p

proc isClockwise*(self: ref Poly): bool =
    var sum = 0
    for i in 0..self.high:
        let line = self[i]
        sum += (line.p1.x * line.p2.y) - (line.p2.x * line.p1.y)
    let
        p1 = self[self.high].p2
        p2 = self[0].p1
    sum += (p1.x * p2.y - p2.x * p1.y)
    result = sum.float / 2.0 > 0

proc points*(self: ref Poly): seq[ref Point] =
    result = newSeq[ref Point]()
    for line in self:
        result.add(clone(line.p1))

proc area*(self: ref Poly): float =
    let points = self.points
    var j: int
    for i in 0..points.high:
        j = (i + 1) mod points.len
        result += float(points[i].x * points[j].y)
        result -= float(points[j].x * points[i].y)
    result = abs(result) / 2.0

proc clone*(self: ref Poly): ref Poly =
    result = newPoly(self.points)

proc inverted*(self: ref Poly): ref Poly =
    result = newPoly()

    if self.len == 0:
        return

    for i in countdown(self.high, 0):
        var
            p1 = clone(self[i].p2)
            p2 = clone(self[i].p1)
        result.add(newLine(p1, p2))

    if self.len == 1:
        return

    var prev = result[0]
    for line in result:
        if line != prev:
            line.prev = prev
            prev.next = line


proc draw*(self: ref Poly, surf: graphics.PSurface, filled = false) =
    var X = newSeq[int16]()
    var Y = newSeq[int16]()

    for line in self:
        X.add((line.p1.x).int16)
        Y.add((line.p1.y).int16)
        X.add((line.p2.x).int16)
        Y.add((line.p2.y).int16)

    if filled:
        discard filledPolygonRGBA(surf.s, addr(X[0]), addr(Y[0]), (len(self) * 2).cint, 128.byte, 20.byte, 20.byte, 255.byte)

    for line in self:
        discard lineRGBA(surf.s, line.p1.x.int16, line.p1.y.int16, line.p2.x.int16, line.p2.y.int16, 255, 255, 255, 255)

proc gen_cut*(self: ref Poly, cuts: ref Poly, start, finish: ref Line): tuple[poly: ref Poly, line: ref Line] =
    result.poly = newPoly()

    var
        head = cuts[0]
        tail = cuts[cuts.high]

    # copy cuts
    var prev_cut = cast[ref Line](nil)
    var new_cuts = newPoly()
    for cut in cuts:
        var new_cut = newLine(clone(cut.p1), clone(cut.p2))
        new_cut.prev = prev_cut
        new_cuts.add(new_cut)
        if prev_cut != nil:
            prev_cut.p2.copy(new_cut.p1)
            prev_cut.next = new_cut
        prev_cut = new_cut

    var new_head = new_cuts[0]
    var new_tail = new_cuts[new_cuts.high]

    # echo("Cuts...")
    # for new_cut in new_cuts:
    #     echo($new_cut)

    # copy curve
    var new_curve = newPoly()
    var prev_edge = cast[ref Line](nil)
    var walker = finish
    while walker != start or new_curve.len == 0:
        var new_edge = newLine(clone(walker.p1), clone(walker.p2))
        new_edge.prev = prev_edge
        new_curve.add(new_edge)
        if prev_edge != nil:
            prev_edge.p2.copy(new_edge.p1)
            prev_edge.next = new_edge
        prev_edge = new_edge
        walker = walker.next

    var start_edge = newLine(clone(start.p1), clone(start.p2))
    if prev_edge != nil:
        start_edge.prev = prev_edge
        prev_edge.next = start_edge
    new_curve.add(start_edge)

    # echo("Curve...")
    # for new_edge in new_curve:
    #     echo($new_edge)

    var curve_head = new_curve[0]
    var curve_tail = new_curve[new_curve.high]
    result.line = curve_tail

    curve_head.p1.copy(new_tail.p2)
    curve_head.prev = new_tail
    new_tail.next = curve_head

    curve_tail.p2.copy(new_head.p1)
    curve_tail.next = new_head
    new_head.prev = curve_tail

    result.poly.add(curve_tail)
    for line in new_cuts:
        result.poly.add(line)
    for i in 0..new_curve.high - 1:
        result.poly.add(new_curve[i])

proc iso_cut*(self, cuts: ref Poly, edge: ref Line): tuple[poly: ref Poly, line: ref Line] =
    result.poly = newPoly()

    var
        head = cuts[0]
        tail = cuts[cuts.high]

    # copy cuts
    var prev_cut = cast[ref Line](nil)
    var new_cuts = newPoly()
    for cut in cuts:
        var new_cut = newLine(clone(cut.p1), clone(cut.p2))
        new_cut.prev = prev_cut
        new_cuts.add(new_cut)
        if prev_cut != nil:
            prev_cut.p2.copy(new_cut.p1)
            prev_cut.next = new_cut
        prev_cut = new_cut

    var new_head = new_cuts[0]
    var new_tail = new_cuts[new_cuts.high]

    # copy edge
    var new_edge = clone(edge)
    result.line = new_edge

    # stitch tail
    new_edge.p1.copy(new_tail.p2)
    new_edge.p2.copy(new_head.p1)
    new_edge.prev = new_tail
    new_tail.next = new_edge
    new_edge.next = new_head
    new_head.prev = new_edge

    result.poly.add(new_edge)
    for line in new_cuts:
        result.poly.add(line)

proc cut*(self: ref Poly, cuts: ref Poly): tuple[poly: ref Poly, line: ref Line] =
    var
        head = cuts[0]
        tail = cuts[cuts.high]

    # find cutting edges
    var
        starts = newSeq[ref Line]()
        finishes = newSeq[ref Line]()
        start, finish: ref Line
    for line in self:
        if line.contains(head.p1):
            starts.add(line)
        if line.contains(tail.p2) and finish == nil:
            finishes.add(line)

    echo("Starts: " & $starts)
    echo("Finishes: " & $finishes)

    if len(starts) != 0:
        start = starts[0]

    if len(finishes) != 0:
        if len(finishes) == 1:
            finish = finishes[0]
        else:
            finish = finishes[1]

    if start == finish:
        let tail_to_next = newLine(clone(tail.p2), clone(start.p2))
        if tail_to_next.contains(head.p1):
            return self.iso_cut(cuts, start)
    return self.gen_cut(cuts, start, finish)