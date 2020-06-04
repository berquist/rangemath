import hashes
import sets
import tables
import unittest

import gara
import sorta

import ../bound

type
  CutPosition* = enum
    below
    above
  CutKind* = enum
    all
    value
  Cut*[T] = object
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
    position*: CutPosition
    case kind*: CutKind
    of CutKind.all:
      nil
    of CutKind.value:
      endpoint*: T

func asLowerBound*[T](c: Cut[T]): Bound =
  case c.kind:
    of CutKind.all:
      raise newException(ValueError, "Should never be called")
    of CutKind.value:
      if c.position == CutPosition.below:
        Bound.closed
      else:
        Bound.open

func asUpperBound*[T](c: Cut[T]): Bound =
  case c.kind:
    of CutKind.all:
      raise newException(ValueError, "Should never be called")
    of CutKind.value:
      if c.position == CutPosition.below:
        Bound.open
      else:
        Bound.closed

func describeAsLowerBound*[T](c: Cut[T]): string =
  case c.kind:
    of CutKind.all: "(-∞"
    of CutKind.value: c.asLowerBound().describeAsLower() & $c.endpoint

func describeAsUpperBound*[T](c: Cut[T]): string =
  case c.kind:
    of CutKind.all: "+∞)"
    of CutKind.value: $c.endpoint & c.asUpperBound().describeAsUpper()

func compare*[T](self, other: Cut[T]): int =
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

func `<`*[T](c: Cut[T], val: T): bool =
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

func `<`*[T](left, right: Cut[T]): bool =
  left.compare(right) < 0

func `<=`*[T](left, right: Cut[T]): bool =
  left.compare(right) <= 0

func `==`*[T](left, right: Cut[T]): bool =
  left.compare(right) == 0

func `>=`*[T](left, right: Cut[T]): bool =
  left.compare(right) >= 0

func `>`*[T](left, right: Cut[T]): bool =
  left.compare(right) > 0

func hash*[T](c: Cut[T]): Hash =
  var h: Hash = 0
  h = h !& c.position.ord
  h = h !& c.kind.ord
  if c.kind == CutKind.value:
    h = h !& c.endpoint
  result = !$h

suite "Cut":
  const
    belowAll = Cut[int](kind: CutKind.all, position: CutPosition.below)
    aboveAll = Cut[int](kind: CutKind.all, position: CutPosition.above)
    belowValue2 = Cut[int](kind: CutKind.value, position: CutPosition.below, endpoint: 2)
    belowValue3 = Cut[int](kind: CutKind.value, position: CutPosition.below, endpoint: 3)
    belowValue4 = Cut[int](kind: CutKind.value, position: CutPosition.below, endpoint: 4)
    aboveValue2 = Cut[int](kind: CutKind.value, position: CutPosition.above, endpoint: 2)
    aboveValue3 = Cut[int](kind: CutKind.value, position: CutPosition.above, endpoint: 3)
    aboveValue4 = Cut[int](kind: CutKind.value, position: CutPosition.above, endpoint: 4)
    # belowAllFloat = Cut[float](kind: CutKind.all, position: CutPosition.below)

  test "hash":
    discard belowAll.hash
    discard aboveAll.hash
    discard aboveValue4.hash
    # discard belowAllFloat.hash

  test "compare":
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
      s = [
        belowAll, belowAll,
        aboveAll, aboveAll,
        belowValue2, belowValue2
      ].toHashSet()
    check: len(s) == 3

  test "Table":
    # Cuts need to be able to be used as keys in tables.
    var
      t1 = initTable[Cut[int], int]()
    t1[belowValue2] = belowValue2.endpoint
    t1[belowValue3] = belowValue3.endpoint
    t1[belowValue4] = belowValue4.endpoint

  test "SortedTable":
    # Cuts need to be able to be used as keys in sorted tables.
    var
      st1 = initSortedTable[Cut[int], int]()
    st1[belowValue4] = belowValue4.endpoint
    st1[belowValue2] = belowValue2.endpoint
    st1[belowValue3] = belowValue3.endpoint
