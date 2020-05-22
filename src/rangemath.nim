import gara
import unittest

type
  Bound* = enum
    open
    closed

func flip(b: Bound): Bound =
  case b:
    of Bound.open: Bound.closed
    of Bound.closed: Bound.open

func describeAsLower(b: Bound): string =
  case b:
    of Bound.open: "("
    of Bound.closed: "["

func describeAsUpper(b: Bound): string =
  case b:
    of Bound.open: ")"
    of Bound.closed: "]"

type
  CutPosition = enum
    below
    above
  CutKind = enum
    all
    value
  Cut[T] = object of RootObj
    ## Implementation detail for the internal structure of Range instances.
    ##
    ## Represents a unique way of "cutting" a "number line" into two sections;
    ## this can be done below a certain value, above a certain value, below
    ## all values, or above all values. With this definition, an interval can
    ## always be represented by a pair of Cut instances.
    ##
    ## This is a Nim port of Python code, originally written by Ryan Gabbard,
    ## which itself is a port of Guava code originally written by Kevin
    ## Bourrillion.
    position: CutPosition
    case kind: CutKind
    of CutKind.all:
      nil
    of CutKind.value:
      endpoint: T

func asLowerBound[T](c: Cut[T]): Bound =
  case c.kind:
    of CutKind.all:
      raise newException(ValueError, "Should never be called")
    of CutKind.value:
      if c.position == CutPosition.below:
        Bound.closed
      else:
        Bound.open

func asUpperBound[T](c: Cut[T]): Bound =
  case c.kind:
    of CutKind.all:
      raise newException(ValueError, "Should never be called")
    of CutKind.value:
      if c.position == CutPosition.below:
        Bound.open
      else:
        Bound.closed

func describeAsLowerBound[T](c: Cut[T]): string =
  case c.kind:
    of CutKind.all: "(-\u221e"
    of CutKind.value: c.asLowerBound().describeAsLower() & $c.endpoint

func describeAsUpperBound[T](c: Cut[T]): string =
  case c.kind:
    of CutKind.all: "+\u221e)"
    of CutKind.value: $c.endpoint & c.asUpperBound().describeAsUpper()

func compare[T](self, other: Cut[T]): int =
  ## A comparator that defines the relationship between two cuts.
  match([self, other]):
    [(kind: CutKind.all, position: CutPosition.below), (kind: CutKind.all, position: CutPosition.below)]:
      0
    [(kind: CutKind.all, position: CutPosition.below), _]:
      -1
    [(kind: CutKind.all, position: CutPosition.above), (kind: CutKind.all, position: CutPosition.above)]:
      0
    [(kind: CutKind.all, position: CutPosition.above), _]:
      1
    [_, (kind: CutKind.all, position: CutPosition.below)]:
      1
    [_, (kind: CutKind.all, position: CutPosition.above)]:
      -1
    [(position: @pos, endpoint: @a), (position: @pos, endpoint: @b)]:
      cmp(a, b)
    [(position: CutPosition.below, endpoint: @a), (position: CutPosition.above, endpoint: @b)]:
      if a <= b: -1
      else: 1
    [(position: CutPosition.above, endpoint: @a), (position: CutPosition.below, endpoint: @b)]:
      if a >= b: 1
      else: -1
    _:
      raise newException(ValueError, "impossible branch")  

func `<`[T](c: Cut[T], val: T): bool =
  case c.kind:
    of CutKind.all:
      if c.position == CutPosition.below: true
      elif c.position == CutPosition.above: false
      else: raise newException(ValueError, "impossible branch")
    of CutKind.value:
      if c.position == CutPosition.below:
        # TODO Why the equality?
        c.endpoint < val or c.endpoint == val
      elif c.position == CutPosition.above:
        c.endpoint < val
      else: raise newException(ValueError, "impossible branch")  

func `<`[T](left, right: Cut[T]): bool =
  left.compare(right) < 0

func `<=`[T](left, right: Cut[T]): bool =
  left.compare(right) <= 0

func `==`*[T](left, right: Cut[T]): bool =
  left.compare(right) == 0

func `>=`[T](left, right: Cut[T]): bool =
  left.compare(right) >= 0

func `>`[T](left, right: Cut[T]): bool =
  left.compare(right) > 0

type
  Range*[T] = object
    ## The boundaries of a contiguous span of values.
    ##
    ## The value must be of some type which implements `<` in a way consistent
    ## with equality. Note this does not provide a means for iterating over
    ## these values.
    ##
    ##
    lowerBound: Cut[T]
    upperBound: Cut[T]

func newRangeOpen*[T](lower, upper: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.value, position: CutPosition.above, endpoint: lower),
           upper_bound: Cut[T](kind: CutKind.value, position: CutPosition.below, endpoint: upper))

func newRangeClosed*[T](lower, upper: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.value, position: CutPosition.below, endpoint: lower),
           upper_bound: Cut[T](kind: CutKind.value, position: CutPosition.above, endpoint: upper))

func newRangeClosedOpen*[T](lower, upper: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.value, position: CutPosition.below, endpoint: lower),
           upper_bound: Cut[T](kind: CutKind.value, position: CutPosition.below, endpoint: upper))

func newRangeOpenClosed*[T](lower, upper: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.value, position: CutPosition.above, endpoint: lower),
           upper_bound: Cut[T](kind: CutKind.value, position: CutPosition.above, endpoint: upper))

func newRangeLessThan*[T](upper: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.all, position: CutPosition.below),
           upper_bound: Cut[T](kind: CutKind.value, position: CutPosition.below, endpoint: upper))

func newRangeAtMost*[T](upper: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.all, position: CutPosition.below),
           upper_bound: Cut[T](kind: CutKind.value, position: CutPosition.above, endpoint: upper))

func newRangeGreaterThan*[T](lower: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.value, position: CutPosition.above, endpoint: lower),
           upper_bound: Cut[T](kind: CutKind.all, position: CutPosition.above))

func newRangeAtLeast*[T](lower: T): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.value, position: CutPosition.below, endpoint: lower),
           upper_bound: Cut[T](kind: CutKind.all, position: CutPosition.above))

func newRangeAll*[T](): Range[T] =
  Range[T](lower_bound: Cut[T](kind: CutKind.all, position: CutPosition.below),
           upper_bound: Cut[T](kind: CutKind.all, position: CutPosition.above))

# func newRangeSpanning[T](s: openArray[Range[T]]): Range[T] =
#   Range[T](lower_bound: Cut[T](),
#            upper_bound: Cut[T]())

func `$`*[T](r: Range[T]): string =
  $r.lowerBound.describeAsLowerBound & ".." & $r.upperBound.describeAsUpperBound

func hasLowerBound*[T](r: Range[T]): bool =
  r.lowerBound != Cut[T](kind: CutKind.all, position: CutPosition.below)

func hasUpperBound*[T](r: Range[T]): bool =
  r.upperBound != Cut[T](kind: CutKind.all, position: CutPosition.above)

func lowerEndpoint*[T](r: Range[T]): T =
  r.lowerBound.endpoint

func upperEndpoint*[T](r: Range[T]): T =
  r.upperBound.endpoint

func lowerBoundType*[T](r: Range[T]): Bound =
  r.lowerBound.asLowerBound

func upperBoundType*[T](r: Range[T]): Bound =
  r.upperBound.asUpperBound

func isEmpty*[T](r: Range[T]): bool =
  r.lowerBound == r.upperBound

func contains*[T](r: Range[T], val: T): bool =
  (r.lowerBound < val) and not (r.upperBound < val)

func encloses*[T](left, right: Range[T]): bool =
  left.lowerBound.compare(right.lowerBound) <= 0 and
  left.upper_bound.compare(right.upper_bound) >= 0

func isConnected*[T](left, right: Range[T]): bool =
  left.lowerBound <= right.upperBound and
  right.lowerBound <= left.upperBound

# TODO span
# TODO intersection
# TODO intersects

suite "Bound":
  test "flip":
    check: Bound.open.flip() == Bound.closed
    check: Bound.closed.flip() == Bound.open

suite "Cut":
  test "compare":
    let
      belowAll = Cut[int](kind: CutKind.all, position: CutPosition.below)
      aboveAll = Cut[int](kind: CutKind.all, position: CutPosition.above)
      belowValue2 = Cut[int](kind: CutKind.value, position: CutPosition.below, endpoint: 2)
      belowValue3 = Cut[int](kind: CutKind.value, position: CutPosition.below, endpoint: 3)
      belowValue4 = Cut[int](kind: CutKind.value, position: CutPosition.below, endpoint: 4)
      aboveValue2 = Cut[int](kind: CutKind.value, position: CutPosition.above, endpoint: 2)
      aboveValue3 = Cut[int](kind: CutKind.value, position: CutPosition.above, endpoint: 3)
      aboveValue4 = Cut[int](kind: CutKind.value, position: CutPosition.above, endpoint: 4)

    check: not (belowAll < belowAll)
    check: (belowAll <= belowAll)
    check: (belowAll == belowAll)
    check: (belowAll >= belowAll)
    check: not (belowAll > belowAll)

    check: not (aboveAll < aboveAll)
    check: (aboveAll <= aboveAll)
    check: (aboveAll == aboveAll)
    check: (aboveAll >= aboveAll)
    check: not (aboveAll > aboveAll)

    check: (belowAll < aboveAll)
    check: (belowAll <= aboveAll)
    check: not (belowAll == aboveAll)
    check: not (belowAll >= aboveAll)
    check: not (belowAll > aboveAll)

    check: (belowValue4 < aboveAll)
    check: (belowValue4 > belowAll)

    check: (belowValue2 < belowValue3)
    check: (belowValue3 < belowValue4)
    check: (aboveValue2 < aboveValue3)
    check: (aboveValue3 < aboveValue4)

    # mixed
    check: (belowValue2 < aboveValue2)
    check: (belowValue2 <= aboveValue2)
    check: not (belowValue2 == aboveValue2)
    check: not (belowValue2 >= aboveValue2)
    check: not (belowValue2 > aboveValue2)

    check: (aboveValue2 < belowValue3)
    check: (aboveValue2 <= belowValue3)
    check: not (aboveValue2 == belowValue3)
    check: not (aboveValue2 >= belowValue3)
    check: not (aboveValue2 > belowValue3)

    check: not (aboveValue4 < belowValue2)
    check: not (aboveValue4 <= belowValue2)
    check: not (aboveValue4 == belowValue2)
    check: (aboveValue4 >= belowValue2)
    check: (aboveValue4 > belowValue2)

    check: not (aboveValue4 < belowValue3)
    check: not (aboveValue4 <= belowValue3)
    check: not (aboveValue4 == belowValue3)
    check: (aboveValue4 >= belowValue3)
    check: (aboveValue4 > belowValue3)

    check: belowValue2.compare(aboveValue2) == -1
    check: belowValue2.compare(aboveValue3) == -1
    check: belowValue3.compare(aboveValue2) == 1
