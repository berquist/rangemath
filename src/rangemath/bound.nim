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

func describeAsLower*(b: Bound): string =
  case b:
    of Bound.open: "("
    of Bound.closed: "["

func describeAsUpper*(b: Bound): string =
  case b:
    of Bound.open: ")"
    of Bound.closed: "]"

suite "Bound":
  test "flip":
    check: Bound.open.flip() == Bound.closed
    check: Bound.closed.flip() == Bound.open
