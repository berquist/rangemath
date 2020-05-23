import hashes

import ./bound,
       ./private/cut

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
  not (r.lowerBound == Cut[T](kind: CutKind.all, position: CutPosition.below))

func hasUpperBound*[T](r: Range[T]): bool =
  not (r.upperBound == Cut[T](kind: CutKind.all, position: CutPosition.above))

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
  left.upperBound.compare(right.upperBound) >= 0

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

func `==`*[T](left, right: Range[T]): bool =
  (left.lowerBound == right.lowerBound) and (left.upperBound == right.upperBound)
