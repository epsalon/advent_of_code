#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
# use POSIX;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}

# Utility function to make sure 2d array has equal rows
# input arr,fill. no output
sub equalize {
  my $arr = shift;
  my $fill = shift;
  my $rows = @$arr;
  my $cols = max(map {$_ ? scalar(@$_): 0} @$arr);
  print "$rows $cols\n";
  for my $row (@$arr) {
    $row = [] unless $row;
    while (@$row < $cols) {
      push @$row, $fill;
    }
  }
}

# Print and array highlighting some cells
# Args:
#   - array ref, row, col, row, col, ...
#   - array ref, "row,col", "row,col", ...
#   - array ref, array of [row, col, row, col, ...]
#   - array ref, array of ["row,col", "row,col", ...]
#   - array ref, array of [[row, col, val?], ...]
#   - array ref, array of [["row,col", val?], ...]
sub hilite {
  my $arr = shift;
  my @hilite = @_;

  # If neighbor array ref, deref
  if (@hilite == 1 && ref($hilite[0])) {
    @hilite = @{$hilite[0]};
  }

  # If the array is raw coords turn into array of [row, col]
  if (@hilite && !ref($hilite[0])) {
    my $h1 = $hilite[0];
    if ($h1 =~ /^\d+,\d+$/o) {
      # "row,col"
      @hilite = map {/^(\d+),(\d+)$/o; [$1,$2]} @hilite;
    } else {
      # row, col, row, col
      @hilite = pairs(@hilite);
    }
  }

  my %hilite;
  for my $h (@hilite) {
    my ($r, $c) = @$h;
    $hilite{"$r,$c"}++;
  }

  my $maxlen = 0;
  for my $r (@$arr) {
    for my $c (@$r) {
      $maxlen=length($c) if length($c) > $maxlen;
    }
  }
  print "     ";
  for my $c (0..$#{$arr->[0]}) {
    print $c % 10 ? ' ':$c/10;
  }
  print "\n     ";
  for my $c (0..$#{$arr->[0]}) {
    print $c % 10;
  }
  print "\n";
  for my $r (0..$#$arr) {
    my $ra = $arr->[$r];
    printf "%4d ", $r;
    for my $c (0..$#$ra) {
      my $v = $ra->[$c];
      print BOLD . ON_RED if $hilite{"$r,$c"};
      printf("%${maxlen}s", $v);
      print RESET;
    }
    print "\n";
  }
  print "\n";
}

# Output a 2d array as text, pad based on longest entry
sub oarr {
  my $arr = \@_;
  unless ($#_) {
    $arr=$_[0];
  }
  return hilite($arr);
}

# Find neighbors
# input
#     neigh_arr, arr, row, col
# OR: neigh_arr, arr, "row,col"
# OR: neigh_arr, rows, cols, row, col
# OR: neigh_arr, rows, cols, "row,col"
# returns
#     array of [row, col, value]
# OR: array of ["row,col", value]
# OR: array of "row,col"
sub neigh {
  my $neigh = shift;
  my ($rows,$cols);
  my $arr = shift;
  if (ref $arr) {
    $rows = @$arr;
    $cols = @{$arr->[0]};
  } else {
    $rows = $arr;
    $cols = shift;
    undef $arr;
  }
  my $row = shift;
  my $col = shift;
  my $comma;
  if ($row =~ /(\d+)(\D+)(\d+)/) {
    ($row, $comma, $col) = ($1, $2, $3);
  }
  my @out;
  for my $pair (@$neigh) {
    my ($rd, $cd) = @$pair;
    my ($nr, $nc) = ($row + $rd, $col + $cd);
    next if $nr < 0;
    next if $nc < 0;
    next if $nr >= $rows;
    next if $nc >= $cols;
    if (defined($comma)) {
      if ($arr) {
        push @out, ["$nr$comma$nc", $arr->[$nr][$nc]];
      } else {
        push @out, "$nr$comma$nc";
      }
    } else {
      push @out, [$nr, $nc, $arr ? ($arr->[$nr][$nc],) : ()];
    }
  }
  return @out;
}

# Orthogonal
sub oneigh {
  return neigh([[-1,0], [1, 0], [0, -1], [0, 1]], @_);
}

# All neighbors
sub aneigh {
  return neigh([
    [-1, -1], [-1, 0], [-1, 1],
    [ 0, -1],          [ 0, 1],
    [ 1, -1], [ 1, 0], [ 1, 1]], @_);
}

# Search/find a rectangle boundary
# Args:
#   array, row 1, col 1, row 2, col 2
# Output:
#   array of [row, col, value]
sub rect {
  my ($array, $r1, $c1, $r2, $c2) = @_;
  my $maxrow = $#$array;
  my $maxcol = $#{$array->[0]};
  ($r1, $r2) = ($r2, $r1) if ($r1 > $r2);
  ($c1, $c2) = ($c2, $c1) if ($c1 > $c2);
  my @out;

  #Horizontal portions
  for my $c ($c1..$c2) {
    next if ($c < 0 || $c > $maxcol);
    if ($r1 <= $maxrow && $r1 >= 0) {
      push @out, [$r1, $c, $array->[$r1][$c]];
    }
    next if ($r1 == $r2);
    if ($r2 <= $maxrow && $r2 >= 0) {
      push @out, [$r2, $c, $array->[$r2][$c]];
    }
  }

  # Vertical portions
  if ($r1 + 1 < $r2) {
    for my $r ($r1+1 .. $r2-1) {
      next if ($r < 0 || $r > $maxcol);
      if ($c1 <= $maxcol && $c1 >= 0) {
        push @out, [$r, $c1, $array->[$r][$c1]];
      }
      next if ($c1 == $c2);
      if ($c2 <= $maxcol && $c2 >= 0) {
        push @out, [$r, $c2, $array->[$r][$c2]];
      }
    }
  }

  return @out;
}

# Numeric sort because sort defaults to lex
# returns new array
sub nsort {
  my $in = \@_;
  if (@$in == 1) {
    $in = $in->[0];
  }
  return sort {$a <=> $b} @$in;
}

# Binary conversions
sub bin2dec {
  my $in = shift;
  return oct("0b$in");
}
sub dec2bin {
  my $in = shift;
  return sprintf ("%b", $in);
}
sub hex2bin {
  my $in = shift;
  return join('', map {sprintf("%04b", oct("0x$_"))} split('', $in));
}
sub bin2hex {
  my $in = shift;
  my $out;
  my @in = split('', $in);
  die "Bad bin value $in" if (@in%4);
  while (@in) {
    $out .= sprintf("%X", bin2dec(join('',splice(@in, 0, 4))));
  }
  return $out;
}

# A* / BFS implementation
# Args: start, end, neighbor function, heuristic function
#  - start is either a node or a list of nodes to start at.
#  - end is either a node or a function that takes a single node
#    and returns true/false.
# - neighbor function: node -> ([new_node, cost], ...)
#   - cost assumed 1 if missing
# - heuristic function: node -> lower bound on cost to end (optional)
sub astar {
  my ($start, $end, $neigh, $h) = @_;
  # Generalize parameters
  $start = [$start] unless (ref($start) eq 'ARRAY');
  if (ref($end) ne 'CODE') {
    my $end_node = $end;
    $end = sub { return $_[0] eq $end_node; };
  }
  die "bad neigh func $neigh" unless (ref($neigh) eq 'CODE');
  $h = sub {return 0;} unless $h;

  # Initialize open list
  my $OPEN = new List::PriorityQueue;
  my %gscore;
  my %OHASH;
  for my $s (@$start) {
    $gscore{$s} = 0;
    $OHASH{$s} = 1;
    $OPEN->insert($s, $h->($s));
  }

  my %path;
  while (%OHASH) {
    my $cur = $OPEN->pop();
    delete $OHASH{$cur};
    # Check for end
    if ($end->($cur)) {
      say "reached end at $cur";
      my $score = $gscore{$cur};
      return $score unless wantarray;
      my @path = ($cur);
      while ($cur = $path{$cur}) {
        unshift(@path, $cur)
      }
      return ($score, @path);
    }
    # Expand neighbors
    for my $n ($neigh->($cur)) {
      my ($np,$v);
      if (ref($n) eq 'ARRAY') {
        ($np,$v) = @$n;
      } else {
        $np = $n;
      }
      if (!defined($v)) {
        $v = 1;
      }
      my $new_g = $gscore{$cur} + $v;
      if (!exists($gscore{$np}) || $new_g < $gscore{$np}) {
        # Found better path to $np
        $path{$np} = $cur if wantarray;
        $gscore{$np} = $new_g;
        my $fscore = $new_g + $h->($np);
        if (!$OHASH{$np}) {
          $OPEN->insert($np, $fscore);
          $OHASH{$np}++;
        } else {
          $OPEN->update($np, $fscore);
        }
      }
    }
  }
}

sub smart_split {
  my $str = shift || $_;
  return ($str =~ m{[a-zA-Z]+|\d+}go);
}

sub hashify {
  my @arr = ref $_[0] ? @{$_[0]} : @_;
  return map {$_ => 1} @arr;
}

# Read a 2d array and possibly empty line after
sub read_2d_array {
  my @arr;
  while (my $v = <>) {
    chomp;
    last unless $_;
    push @arr, [split('')];
  }
  return @arr;
}

# arr_to_coords
# Usage:
#   arr_to_coords('.', @A)
#   arr_to_coords(sub {/[abc]/}, @A)
#   arr_to_coords(\{'.' => 1, '*' => 1}, @A)
#
# Returns (wantarray):
#   ("0,0", "0,2", ...)
# Otherwise:
#   \{"0,0" => '.', "0,2" => '$', ...}
#
# Example:
#   while (my @A = arr_to_coords('#', read_2d_array())) { ...
#
sub arr_to_coords {
  my $match_par = shift;
  my $match;
  if (ref($match_par) eq '') {
    $match = sub {$_[0] eq $match_par};
  } elsif (ref($match_par) eq 'HASH') {
    $match = sub {$match_par->{$_[0]}};
  } elsif (ref($match_par) eq 'CODE') {
    $match = sub {local $_; $_=$_[0]; $match_par->()};
  } else {
    die "Bad match parameter - $match_par";
  }

  my @arr = @_;
  if (@arr == 1 && ref($arr[0][0])) {
    @arr = @{$arr[0]};
  }

  my %ret;
  for my $r (0..$#arr) {
    for my $c (0..$#{$arr[0]}) {
      if ($match->($arr[$r][$c])) {
        $ret{"$r,$c"} = $arr[$r][$c];
      }
    }
  }
  if (wantarray) {
    return keys(%ret);
  } else {
    return \%ret;
  }
}

# Transpose a two dimensional array
# Usage:
#  transpose('....#..#..', '....#..#..', ...)
#  transpose(['.', '.', '#' ...], ['.', '.', '#' ...], ...)
#  transpose('0,1', '2,1', '3,2')
#  transpose(\{'0,1' => 1, '2,1' => 1, ...})
#
# Returns results in same form as input.
sub transpose {
  my $sarr=\@_;
  # actual transpose
  my @oarr;
  for my $c (0..length($sarr->[0])-1) {
    my $orow;
    for my $r (0..$#$sarr) {
      $orow.=substr($sarr->[$r],$c,1);
    }
    push @oarr, $orow;
  }

  return (wantarray ? @oarr : \@oarr);
}

# Executes a cyclic procedure a large number of times
#
# Args:
#  - fun(state, n) - returns new state (must be hashable)
#      will always be called on the previous returned state.
#  - num_iters - large number of iterations
#  - start_state - must be hashable
#
# Returns:
#  - state after num_iters
# or:
#  - (end_state, pre_cycle_length, cycle_length)
#
sub find_cycle {
  my $fun = shift;
  my $num_iters = shift;
  my $state = shift || '';
  my %seen;
  my $n=0;
  while (!defined($seen{$state})) {
    $seen{$state}=$n;
    local $_;
    $_ = $state;
    $state = $fun->($state, $n++);
  }
  my $prev = $seen{$state};
  my $cyc = $n - $prev;
  my $extra = ($num_iters - $prev) % $cyc;

  for my $i (1..$extra) {
    local $_;
    $_ = $state;
    $state = $fun->($state, $n++);
  }
  return wantarray ? ($state, $prev, $cyc) : $state;
}

sub tilt {
  my $dir = shift;
  my @Q;
  for my $r (@_) {
    my $p;
    do {
      $p = $r;
      if ($dir) {
        $r =~ s{\.O}{O\.}go;
      } else {
        $r =~ s{O\.}{\.O}go;
      }
    } while ($p ne $r);
    push @Q, $r;
  }
  return @Q;
}

sub cycle {
  return tilt(0,transpose(tilt(0,transpose(tilt(1,transpose(tilt(1,transpose(@_))))))));
}

sub score {
  my @Q=transpose(@_);
  my $sum;
  for my $r (@Q) {
    my @s = split('', $r);
    for my $i (0..$#s) {
      $sum+=@s-$i if ($s[$i] eq 'O');
    }
  }
  return $sum;
}

my @Q;
while (<>) {
  chomp;
  push @Q,$_;
}

out(score(transpose(tilt(1,transpose(@Q)))));

find_cycle(sub {
  @Q=cycle(@Q);
  return join('', @Q);
}, 1000000000, join('', @Q));

out (score(@Q));
