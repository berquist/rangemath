import options
import unittest

import ../src/rangemath/span

suite "Span":

  test "index":
    discard

  test "disjoint_index":
    discard

  test "intersection":
    let
      s1 = newSpanFromInclusiveToExclusive(0, 3)
      s2 = newSpanFromInclusiveToExclusive(2, 25)
      s3 = newSpanFromInclusiveToExclusive(25, 30)
      s1_s2_intersection = newSpanFromInclusiveToExclusive(2, 3)
    check: s1.intersection(s3) == none(Span)
    check: s2.intersection(s3) == none(Span)
    check: s1.intersection(s2) == some(s1_s2_intersection)
