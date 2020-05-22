import rangemath
import unittest

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
    check: rng.hasUpperBound()
    check: rng.upperEndpoint == 5
    check: rng.upperBoundType == Bound.open
    check: not rng.isEmpty()
    check: $rng == "(-\u221e..5)"

  test "GreaterThan":
    let rng = newRangeGreaterThan(5)
    # TODO tests
    check: $rng == "(5..+\u221e)"

  test "AtLeast":
    let rng = newRangeAtLeast(6)
    # TODO tests
    check: $rng == "[6..+\u221e)"

  test "AtMost":
    let rng = newRangeAtMost(4)
    # TODO tests
    check: $rng == "(-\u221e..4]"

  test "All":
    let rng = newRangeAll[int]()
    # TODO tests
    check: $rng == "(-\u221e..+\u221e)"
