import options
import sequtils
import sugar

import ./range

type
  Span* = object
    ## A range of character offsets.
    ##
    ## Inclusive of ``start``, exclusive of ``stop``.
    ##
    ## You can test sub-span containment with the ``in`` operator. For
    ## checking whether an offset lies in a span, use ``contains_offset``.
    start*: int
    stop*: int

func newSpanFromInclusiveToExclusive*(startInclusive, endExclusive: int): Span =
  if not (startInclusive < endExclusive):
    raise newException(
      ValueError,
      "Start offset must be strictly less then end offset but got [" & $startInclusive & "," & $endExclusive & ")"
    )
  Span(start: startInclusive, stop: endExclusive)

func containsOffset*(s: Span, i: int): bool =
  s.start <= i and i < s.stop

func containsSpan*(s, other: Span): bool =
  (s.start <= other.start) and (other.stop <= s.stop)

func precedes*(first, second: Span): bool =
  ## Get whether the first span precedes the second.
  ##
  ## To be judged as preceding, the first span must end before the second
  ## begins.
  first.stop <= second.start

func follows*(first, second: Span): bool =
  ## Get whether the first span follows the second.
  ##
  ## To be judged as following, the first span must start after the second
  ## ends.
  first.start >= second.stop

func overlaps*(first, second: Span): bool =
  ## Get whether the first span overlaps the second.
  ##
  ## Two spans overlap if at least one offset position is in both of them.
  # if they don't overlap, one must precede the other
  not (first.precedes(second) or second.precedes(first))

func asRange*(s: Span): Range[int] =
  newRangeClosed(s.start, s.stop - 1)

func contains*(s, other: Span): bool =
  s.containsSpan(other)

func len*(s: Span): int =
  s.stop - s.start

func clipTo*(s, enclosing: Span): Option[Span] =
  ## Get a copy of the first span clipped to be entirely enclosed by the
  ## second span.
  ##
  ## If the first span lies entirely outside ``enclosing``, return ``none``.
  if not enclosing.overlaps(s):
    none(Span)
  elif enclosing in s:
    some(s)
  else:
    some(
      newSpanFromInclusiveToExclusive(max(s.start, enclosing.start),
                                      min(s.stop, enclosing.stop))
    )

func shift*(s: Span, shiftAmount: int): Span =
  ## Get a copy of this span with both endpoints shifted.
  ##
  ## Negative values shift the span to the left, positive to the right.
  newSpanFromInclusiveToExclusive(s.start + shiftAmount, s.stop + shiftAmount)

func minimalEnclosingSpan*(spans: openArray[Span]): Span =
  ## Get the minimal span enclosing all given spans.
  ##
  ## This will raise a ``ValueError`` if ``spans`` is empty.
  if spans.len == 0:
    raise newException(
      ValueError,
      "Can't get the minimal enclosing span of an empty collection of spans"
    )
  else:
    result = newSpanFromInclusiveToExclusive(
      spans.map(s => s.start).min,
      spans.map(s => s.stop).max
    )

# func earliestThenLogestFirstKey(x: Span): tuple[int, int] =
#   (x.start, -x.len)

func `$`(x: Span): string =
  "[" & $x.start & ":" & $x.stop & ")"

func intersection*(first, second: Span): Option[Span] =
  ## Gets the intersection of two Spans if they overlap.
  if first.overlaps(second):
    let rangeIntersection = first.asRange().intersection(second.asRange())
    result = some(
      newSpanFromInclusiveToExclusive(
        rangeIntersection.lowerEndpoint, rangeIntersection.upperEndpoint + 1
      )
    )
  else:
    result = none(Span)
