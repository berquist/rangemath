import sets
import unittest

import ../src/rangemath/bound,
       ../src/rangemath/range

## Tests for Range.
##
## Almost entirely taken from Guava's Range tests (author Kevin Bourrillion)
suite "Range":

  test "Open":
    let rng = newRangeOpen(4, 8)
    check: rng.hasLowerBound()
    check: rng.lowerEndpoint == 4
    check: rng.lowerBoundType == Bound.open
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 8
    check: rng.upperBoundType == Bound.open
    check: not rng.isEmpty()
    check: $rng == "(4..8)"
    # TODO
    # with self.assertRaises(ValueError):
    #     Range.open(8, 4)
    # with self.assertRaises(ValueError):
    #     Range.open(4, 4)

  test "Closed":
    let rng = newRangeClosed(5, 7)
    check: rng.hasLowerBound()
    check: rng.lowerEndpoint == 5
    check: rng.lowerBoundType == Bound.closed
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 7
    check: rng.upperBoundType == Bound.closed
    check: not rng.isEmpty()
    check: $rng == "[5..7]"
    # workaround to make sure this can be constructed
    check: newRangeClosed(4, 4) == newRangeClosed(4, 4)
    # TODO
    # with self.assertRaises(ValueError):
    #   Range.closed(8, 4)


  test "OpenClosed":
    let rng = newRangeOpenClosed(4, 7)
    check: rng.hasLowerBound()
    check: rng.lowerEndpoint == 4
    check: rng.lowerBoundType == Bound.open
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 7
    check: rng.upperBoundType == Bound.closed
    check: not rng.isEmpty()
    check: $rng == "(4..7]"

  test "ClosedOpen":
    let rng = newRangeClosedOpen(5, 8)
    check: rng.hasLowerBound()
    check: rng.lowerEndpoint == 5
    check: rng.lowerBoundType == Bound.closed
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 8
    check: rng.upperBoundType == Bound.open
    check: not rng.isEmpty()
    check: $rng == "[5..8)"

  test "singleton":
    let rng = newRangeClosed(4, 4)
    check: 3 notin rng
    check: 4 in rng
    check: 5 notin rng
    check: rng.hasLowerBound()
    check: rng.lowerEndpoint == 4
    check: rng.lowerBoundType == Bound.closed
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 4
    check: rng.upperBoundType == Bound.closed
    check: not rng.isEmpty()
    check: $rng == "[4..4]"

  test "empty_1":
    let rng = newRangeClosedOpen(4, 4)
    check: 3 notin rng
    check: 4 notin rng
    check: 5 notin rng
    check: rng.hasLowerBound()
    check: rng.lowerEndpoint == 4
    check: rng.lowerBoundType == Bound.closed
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 4
    check: rng.upperBoundType == Bound.open
    check: rng.isEmpty()
    check: $rng == "[4..4)"

  test "empty_2":
    let rng = newRangeOpenClosed(4, 4)
    check: 3 notin rng
    check: 4 notin rng
    check: 5 notin rng
    check: rng.hasLowerBound()
    check: rng.lowerEndpoint == 4
    check: rng.lowerBoundType == Bound.open
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 4
    check: rng.upperBoundType == Bound.closed
    check: rng.isEmpty()
    check: $rng == "(4..4]"

  test "LessThan":
    let rng = newRangeLessThan(5)
    check: low(int) in rng
    check: 4 in rng
    check: 5 notin rng
    check: high(int) notin rng
    check: not rng.hasLowerBound()
    # TODO
    # self.assert_unbounded_below(rng)
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 5
    check: rng.upperBoundType == Bound.open
    check: not rng.isEmpty()
    check: $rng == "(-∞..5)"

  test "GreaterThan":
    let rng = newRangeGreaterThan(5)
    check: low(int) notin rng
    check: 5 notin rng
    check: 6 in rng
    check: high(int) in rng
    check: rng.hasLowerBound()
    # TODO
    # self.assert_unbounded_above(rng)
    check: not rng.hasUpperBound()
    check: rng.lowerEndpoint == 5
    check: rng.lowerBoundType() == Bound.open
    check: not rng.isEmpty()
    check: $rng == "(5..+∞)"

  test "AtLeast":
    let rng = newRangeAtLeast(6)
    check: low(int) notin rng
    check: 5 notin rng
    check: 6 in rng
    check: high(int) in rng
    check: rng.hasLowerBound()
    check: not rng.hasUpperBound()
    # TODO
    # self.assert_unbounded_above(rng)
    check: rng.lowerEndpoint == 6
    check: rng.lowerBoundType() == Bound.closed
    check: not rng.isEmpty()
    check: $rng == "[6..+∞)"

  test "AtMost":
    let rng = newRangeAtMost(4)
    check: low(int) in rng
    check: 4 in rng
    check: 5 notin rng
    check: high(int) notin rng
    check: not rng.hasLowerBound()
    # TODO
    # self.assert_unbounded_below(rng)
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 4
    check: rng.upperBoundType() == Bound.closed
    check: not rng.isEmpty()
    check: $rng == "(-∞..4]"

  test "All":
    let rng = newRangeAll[int]()
    check: low(int) in rng
    check: high(int) in rng
    check: not rng.hasLowerBound()
    check: not rng.hasUpperBound()
    # TODO
    # self.assert_unbounded_below(rng)
    # self.assert_unbounded_above(rng)
    check: not rng.isEmpty()
    check: $rng == "(-∞..+∞)"

  test "equals":
    check: newRangeAll[int]() == newRangeAll[int]()
    check: newRangeGreaterThan(2) == newRangeGreaterThan(2)
    check: newRangeOpen(1, 5) == newRangeOpen(1, 5)

  test "encloses_open":
    let rng = newRangeOpen(2, 5)

    check: rng.encloses(rng)
    check: rng.encloses(newRangeOpen(2, 4))
    check: rng.encloses(newRangeOpen(3, 5))
    check: rng.encloses(newRangeClosed(3, 4))

    check: not rng.encloses(newRangeOpenClosed(2, 5))
    check: not rng.encloses(newRangeClosedOpen(2, 5))
    check: not rng.encloses(newRangeClosed(1, 4))
    check: not rng.encloses(newRangeClosed(3, 6))
    check: not rng.encloses(newRangeGreaterThan(3))
    check: not rng.encloses(newRangeLessThan(3))
    check: not rng.encloses(newRangeAtLeast(3))
    check: not rng.encloses(newRangeAtMost(3))
    check: not rng.encloses(newRangeAll[int]())

  test "encloses_closed":
    let rng = newRangeClosed(2, 5)

    check: rng.encloses(rng)
    check: rng.encloses(newRangeOpen(2, 5))
    check: rng.encloses(newRangeOpenClosed(2, 5))
    check: rng.encloses(newRangeClosedOpen(2, 5))
    check: rng.encloses(newRangeClosed(3, 5))
    check: rng.encloses(newRangeClosed(2, 4))

    check: not rng.encloses(newRangeOpen(1, 6))
    check: not rng.encloses(newRangeGreaterThan(3))
    check: not rng.encloses(newRangeLessThan(3))
    check: not rng.encloses(newRangeAtLeast(3))
    check: not rng.encloses(newRangeAtMost(3))
    check: not rng.encloses(newRangeAll[int]())

  test "intersection_empty":
    let rng = newRangeClosedOpen(3, 3)
    check: rng.intersection(rng) == rng
    # TODO
    # with self.assertRaises(ValueError):
    #     rng.intersection(Range.open(3, 5))
    # with self.assertRaises(ValueError):
    #     rng.intersection(Range.closed(0, 2))

  test "intersection_def_facto_empty":
    let rng = newRangeOpen(3, 4)
    check: rng.intersection(rng) == rng
    check: rng.intersection(newRangeAtMost(3)) == newRangeOpenClosed(3, 3)
    check: rng.intersection(newRangeAtLeast(4)) == newRangeClosedOpen(4, 4)
    # TODO
    # with self.assertRaises(ValueError):
    #     rng.intersection(Range.less_than(3))
    # with self.assertRaises(ValueError):
    #     rng.intersection(Range.greater_than(4))
    check: newRangeClosed(3,4).intersection(newRangeGreaterThan(4)) == newRangeOpenClosed(4, 4)

  test "intersection_singleton":
    let rng = newRangeClosed(3, 3)
    check:rng.intersection(rng) == rng

    check: rng.intersection(newRangeAtMost(4)) == rng
    check: rng.intersection(newRangeAtMost(3)) == rng
    check: rng.intersection(newRangeAtLeast(3)) == rng
    check: rng.intersection(newRangeAtLeast(2)) == rng

    check: rng.intersection(newRangeLessThan(3)) == newRangeClosedOpen(3, 3)
    check: rng.intersection(newRangeGreaterThan(3)) == newRangeOpenClosed(3, 3)

    # TODO
    # with self.assertRaises(ValueError):
    #     rng.intersection(Range.at_least(4))
    # with self.assertRaises(ValueError):
    #     rng.intersection(Range.at_most(2))

  test "intersection_general":
    let rng = newRangeClosed(4, 8)
    # separate
    # TODO
    # with self.assertRaises(ValueError):
    #   rng.intersection(Range.closed(0, 2))
    # adjacent below
    check: rng.intersection(newRangeClosedOpen(2, 4)) == newRangeClosedOpen(4, 4)
    # overlap below
    check: rng.intersection(newRangeClosed(2, 6)) == newRangeClosed(4, 6)
    # enclosed with same start
    check: rng.intersection(newRangeClosed(4, 6)) == newRangeClosed(4, 6)
    # enclosed, interior
    check: rng.intersection(newRangeClosed(5, 7)) == newRangeClosed(5, 7)
    # enclosed with same end
    check: rng.intersection(newRangeClosed(6, 8)) == newRangeClosed(6, 8)
    # equal
    check: rng.intersection(rng) == rng
    # enclosing with same start
    check: rng.intersection(newRangeClosed(4, 10)) == rng
    # enclosing with same end
    check: rng.intersection(newRangeClosed(2, 8)) == rng
    # enclosing, exterior
    check: rng.intersection(newRangeClosed(2, 10)) == rng
    # overlap above
    check: rng.intersection(newRangeClosed(6, 10)) == newRangeClosed(6, 8)
    # adjacent above
    check: rng.intersection(newRangeOpenClosed(8, 10)) == newRangeOpenClosed(8, 8)
    # TODO
    # with self.assertRaises(ValueError):
    #     rng.intersection(Range.closed(10, 12))

  test "intersects":
    let rng = newRangeClosed(4, 8)
    # separate
    check: not rng.intersects(newRangeClosed(0, 2))
    # adjacent below
    check: rng.intersects(newRangeClosedOpen(2, 4))
    # overlap below
    check: rng.intersects(newRangeClosed(2, 6))
    # enclosed with same start
    check: rng.intersects(newRangeClosed(4, 6))
    # enclosed, interior
    check: rng.intersects(newRangeClosed(5, 7))
    # enclosed with same end
    check: rng.intersects(newRangeClosed(6, 8))
    # equal
    check: rng.intersects(rng)
    # enclosing with same start
    check: rng.intersects(newRangeClosed(4, 10))
    # enclosing with same end
    check: rng.intersects(newRangeClosed(2, 8))
    # enclosing, exterior
    check: rng.intersects(newRangeClosed(2, 10))
    # overlap above
    check: rng.intersects(newRangeClosed(6, 10))
    # adjacent above
    check: rng.intersects(newRangeOpenClosed(8, 10))
    check: not rng.intersects(newRangeClosed(10, 12))

  test "create_spanning":
    discard
    # TODO
    # with self.assertRaisesRegex(
    #     ValueError, "Cannot create range from span of empty range collection"
    # ):
    #     Range.create_spanning([])

  test "check_usable_in_set":
    let setOfRanges = [
      newRangeOpenClosed(0, 1),
      newRangeOpenClosed(0, 1),
      newRangeAtMost(1),
      newRangeAtMost(1)
    ].toHashSet()
    check: len(setOfRanges) == 2

  # TODO
  # def assert_unbounded_below(self, rng: Range):
  #     self.assertFalse(rng.has_lower_bound())
  #     with self.assertRaises(ValueError):
  #         rng.lower_endpoint()
  #     # pylint: disable=pointless-statement
  #     with self.assertRaises(AssertionError):
  #         rng.lower_bound_type

  # TODO
  # def assert_unbounded_above(self, rng: Range):
  #     self.assertFalse(rng.has_upper_bound())
  #     with self.assertRaises(ValueError):
  #         rng.upper_endpoint()
  #     # pylint: disable=pointless-statement
  #     with self.assertRaises(AssertionError):
  #         rng.upper_bound_type

