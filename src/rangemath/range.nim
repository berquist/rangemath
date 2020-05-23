import gara
import hashes
import sets
import unittest

type
  Bound* = enum
    ## A possible type of boundary for a range.
    ##
    ## A boundary is either
    ## - closed, meaning it includes its endpoint, or
    ## - open, meaning it does not.
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
  Cut[T] = object
    ## Implementation detail for the internal structure of Range instances.
    ##
    ## Represents a unique way of "cutting" a "number line" into two sections;
    ## this can be done below a certain value, above a certain value, below
    ## all values, or above all values. With this definition, an interval can
    ## always be represented by a pair of Cut instances.
    ##
    ## This is a Nim port of Python code from
    ## https://github.com/isi-vista/vistautils, which itself is a port of
    ## Guava code originally written by Kevin Bourrillion.
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
    of CutKind.all: "(-∞"
    of CutKind.value: c.asLowerBound().describeAsLower() & $c.endpoint

func describeAsUpperBound[T](c: Cut[T]): string =
  case c.kind:
    of CutKind.all: "+∞)"
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

func hash[T](c: Cut[T]): Hash =
  var h: Hash = 0
  h = h !& c.position.ord
  h = h !& c.kind.ord
  if c.kind == CutKind.value:
    h = h !& c.endpoint
  result = !$h

type
  Range*[T] = object
    ## The boundaries of a contiguous span of values.
    ##
    ## The value must be of some type which implements ``<`` in a way
    ## consistent with equality. Note this does not provide a means for
    ## iterating over these values.
    ##
    ## Each end of the Range may be *bounded* or *unbounded*. If bounded,
    ## there is an associated *endpoint* value and the range is considered
    ## either *open* (does not include the endpoint value) or *closed* (does
    ## include the endpoint value). With three possibilities on each side,
    ## this yields nine basic types of ranges, enumerated below.
    ##
    ## (Notation: a square bracket (``[ ]``) indicates that the range is
    ## closed on that side; a parenthesis (``( )``) means it is either open or
    ## unbounded. The construct ``{x | statement}`` is read "the set of all x
    ## such that statement".)
    ##
    ##
    ## When both endpoints exist, the upper endpoint may not be less than the
    ## lower. The endpoints may be equal only if at least one of the bounds is
    ## closed:
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
  ## Determine if a range is empty.
  ##
  ## Returns ``True`` if the range is of the form ``[v..v)`` or `(v..v]`.
  ## (This does not encompass ranges of the form ``(v..v)``, because such
  ## ranges are invalid and can't be constructed at all.)
  ##
  ## Note that certain discrete ranges such as the integer range ``(3..4)``
  ## are not considered empty, even though the contain no actual values.
  r.lowerBound == r.upperBound

func contains*[T](r: Range[T], val: T): bool =
  ## Does the range contain the given value?
  (r.lowerBound < val) and not (r.upperBound < val)

func encloses*[T](left, right: Range[T]): bool =
  ## Does the first range enclose the second range?
  left.lowerBound.compare(right.lowerBound) <= 0 and
  left.upper_bound.compare(right.upper_bound) >= 0

func isConnected*[T](left, right: Range[T]): bool =
  ## Determine if two ranges are connected.
  ##
  ## Returns ``true`` if there exists a (possibly empty) range which is
  ## enclosed by both of the given ranges. For example,
  ## - ``[2..4)`` and ``[5..7)`` are not connected
  ## - ``[2..4)`` and ``[3..5)`` are connected, because both enclose ``[3..4)``
  ## - ``[2..4)`` and ``[4..6)`` are connected, because both enclose the empty range ``[4..4)``
  ##
  ## Note that both ranges have a well-defined union and intersection (as a
  ## single, possibly-empty range) if and only if this method returns
  ## ``true``.
  ##
  ## The connectectedness relation is both reflexive and symmetric, but does
  ## not form an equivalence relation as it is not transitive.
  ##
  ## Note that certain discrete ranges are not considered connected, even
  ## though there are no elements "between them". For example, ``[3..5]`` is
  ## not considered connected to ``[6..10]``.
  left.lowerBound <= right.upperBound and
  right.lowerBound <= left.upperBound

func span*[T](left, right: Range[T]): Range[T] =
  ## Get the minimal range enclosing both ranges.
  ##
  ## For example, the span of ``[1..3]`` and ``(5..7)`` is ``[1..7)``. If the
  ## input ranges are connected, the returned range can also be called their
  ## union. If they are not, note that the span might contain values that are
  ## not contained in either input range.
  ##
  ## Like intersection, this operation is commutative, associative and
  ## idempotent. Unlike intersection, it is always well-defined for any two
  ## input ranges.
  let
    lowerCmp = left.lowerBound.compare(right.lowerBound)
    upperCmp = left.upperBound.compare(right.upperBound)
  if lowerCmp <= 0 and upperCmp >= 0:
    left
  elif lowerCmp >= 0 and upperCmp <= 0:
    right
  else:
    Range[T](lowerBound: if lowerCmp <= 0: left.lowerBound else: right.lowerBound,
             upperBound: if upperCmp >= 0: left.upperBound else: right.upperBound)

func intersection*[T](left, right: Range[T]): Range[T] =
  ## Get the intersection of both ranges.
  ##
  ## Returns the maximal range enclosed by both ranges, if such a range
  ## exists.
  ##
  ## For example, the intersection of ``[1..5]`` and ``(3..7)`` is
  ## ``(3..5]``. The resulting range may be empty; for example, ``[1..5)``
  ## intersected with ``[5..7)`` yields the empty range ``[5..5)``.
  ##
  ## The intersection exists if and only if the two ranges are connected. TODO
  ## This method throws a ``ValueError`` if this does not hold true.
  ##
  ## The intersection operation is commutative, associative and idempotent,
  ## and its identity element is the ``all`` range.
  let
    lowerCmp = left.lowerBound.compare(right.lowerBound)
    upperCmp = left.upperBound.compare(right.upperBound)
  if lowerCmp >= 0 and upperCmp <= 0:
    left
  elif lowerCmp <= 0 and upperCmp >= 0:
    right
  else:
    Range[T](lowerBound: if lowerCmp >= 0: left.lowerBound else: right.lowerBound,
             upperBound: if upperCmp <= 0: left.upperBound else: right.upperBound)

func intersects*[T](left, right: Range[T]): bool =
  ## Do the two given ranges intersect?
  let
    lowerCmp = left.lowerBound.compare(right.lowerBound)
    upperCmp = left.upperBound.compare(right.upperBound)
  if lowerCmp >= 0 and upperCmp <= 0:
    true
  elif lowerCmp <= 0 and upperCmp >= 0:
    true
  else:
    let
      intersectionLowerBound = if lowerCmp >= 0: left.lowerBound else: right.lowerBound
      intersectionUpperBound = if upperCmp <= 0: left.upperBound else: right.upperBound
    intersectionLowerBound <= intersectionUpperBound

func hash*[T](r: Range[T]): Hash =
  var h: Hash = 0
  h = h !& hash(r.lowerBound)
  h = h !& hash(r.upperBound)
  result = !$h

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

  test "hash":
    let
      belowAll = Cut[int](kind: CutKind.all, position: CutPosition.below)
      aboveAll = Cut[int](kind: CutKind.all, position: CutPosition.above)
      belowValue2 = Cut[int](kind: CutKind.value, position: CutPosition.below, endpoint: 2)
      s = [
        belowAll, belowAll,
        aboveAll, aboveAll,
        belowValue2, belowValue2
      ].toHashSet()
    check: len(s) == 3
