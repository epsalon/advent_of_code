# AoC Grid library

What you need to know.

## Constructors

### Read the input

```perl
my $grid = Grid::Dense->read($fh);  # $fh defaults to \*ARGV
my $grid = Grid::Dense->from_string($input);
```
### new

```perl
my $grid = Grid::Dense->new(\@2d_arr);
```

## Accessors

### at

```perl
my $v = $grid->at($r,$c); # Read the value at $r,$c.
```

### bounds

```perl
if ($grid->bounds($r,$c)) { # Returns true if position is in bounds.
```

### get_bounds / rows / cols
```perl
my ($min_row,$min_col,$max_row,$max_col) = $grid->get_bounds();
my $rows = $grid->rows();
my $cols = $grid->cols();
```

### iterate

Runs interator on each coord, return value ignored.

```perl
$grid->iterate(sub{
    my ($r,$c,$v) = @_;
})
```

### neigh / oneigh / aneigh

Find neighbors within bounds.

```perl
# Orthogonal neighbords
my @n1 = $grid->oneigh($r,$c);
# Returns: ([$r1,$c1,$v1], [$r2,$c2,$v2], ...)

# All neighbors
my @n2 = $grid->aneigh("$r,$c");
# Returns: (["$r1,$c1",$v1], ["$r2,$c2",$v2], ...)

# Custom neighbors (in this case, up and down only)
my @n3 = $grid->neigh([[-1,0], [1, 0]], $r, $c); 

```

### to_str / print

Debug functions, render as a string. Accepts array of coords to hilight.

See [Coord array encodings](#coord-array-encodings).

```perl
print $grid->to_str($r, $c);  # Highlight ($r,$c)

$grid->print(@hilights);
```

### as_array (dense only)

Convert to 2D array
```perl
my $aref = $grid->as_array();  # array ref
my @arr  = $grid->as_array();  # actual array
```

## Mutators

### transpose / flipH / flipV / rot90R /rot90L / rot180

Grid manipulation, all lazy, no args.

### set

```perl
$grid->set($r,$c,$v); # set r,c to value v.
```

### floodfill

```perl
$grid->floodfill($r, $c, $boundary, $set, $seen_hash)
```

`$boundary` is one of:

* `undef`: boundary is if the value is true.
* `\%hash`: boundary if `$hash{$value}` is true.
* `$scalar` : boundary if value is `eq $scalar`.
* `\&sub`: boundary if `$sub->($value)` is true.

`$set` is one of:

* `undef`: fill with 1.
* `$scalar`: fill with the scalar.
* `\&sub`: Call `$sub->($r,$c)` on each fill spot.

`$seen_hash` if one of:
* true but not a hash: Use a seen_hash as a boundary.
* false: Do not use a seen_hash as boundary
* `undef`: Do not use a seen_hash as boundary unless `$set ne $boundary`.
* `\%hash`: Use `%hash` as the seen hash, keys are `"$r,$c"`.

## Coord array encodings

Multiple encodings supported:

* Flat array

  ```perl
  my @a = ($r1, $c1, $r2, $c2);
  ```

* Array of pairs (additional values ignored)

  ```perl
  my @a = ([$r1, $c1], [$r2, $c2]);
  my @a = ([$r1, $c1, $v1], [$r2, $c2, $v2]);
  ```

* Array of string pairs
  ```perl
  my @a = ("$r1,$c1", "$r2,$c2");
  ```
