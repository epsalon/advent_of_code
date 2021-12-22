#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Bit::Vector;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
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

# Find neighbors
# input neigh_arr, arr, row, col
# OR: neigh_arr, arr, "row,col"
# OR: neigh_arr, rows, cols, row, col
# OR: neigh_arr, rows, cols, "row,col"
# returns array of [row, col, value]
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
# neighbor function: node -> [[new_node, cost], ...]
#   cost assumed 1 if missing
# heuristic function: node -> lower bound on cost to end
sub astar {
  my ($start, $end, $neigh, $h) = @_;
  $h = sub {return 0;} unless $h;

  my $OPEN = new List::PriorityQueue;
  my %gscore = ($start, 0);
  my %OHASH = ($start, 1);
  my %path;
  $OPEN->insert($start, $h->($start));

  while (%OHASH) {
    my $cur = $OPEN->pop();
    delete $OHASH{$cur};
    if ($cur eq $end) {
      my $score = $gscore{$cur};
      return $score unless wantarray;
      my @path = ($cur);
      while ($cur = $path{$cur}) {
        unshift(@path, $cur)
      }
      return ($score, @path);
    }
    for my $n ($neigh->($cur)) {
      my ($np,$v) = @$n;
      if (!defined($v)) {
        $v = 1;
      }
      my $new_g = $gscore{$cur} + $v;
      if (!exists($gscore{$np}) || $new_g < $gscore{$np}) {
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

my @A;

sub intervaldiff {
  my ($s1,$e1,$s2,$e2) = @_;
  my @list = ([$s1,1], [$e1,-1], [$s2,-1], [$e2,1]);
  @list=sort {$a->[0] <=> $b->[0]} @list;
  #say "ID($s1,$e1,$s2,$2) called: ", join('; ', map {join(',', @$_)} @list);
  my @out;
  my $v=0;
  for my $i (0..$#list-1) {
    $v+=$list[$i]->[1];
    next if $list[$i]->[0] == $list[$i+1]->[0];
    if ($v > 0) {
      push @out, [$list[$i]->[0], $list[$i+1]->[0]];
    }
  }
  return @out;
}

sub printlist {
  say join('; ', map {join(',', @$_)} @_), " => ", sum(map {volume($_)} @_);
}

sub prismdiff {
  my ($p1,$p2) = @_;
  #printlist ($p1);
  #printlist ($p2);
  my @out;
  for my $x (intervaldiff($p1->[0], $p1->[1], $p2->[0], $p2->[1])) {
    my $p = [@$x, $p1->[2], $p1->[3], $p1->[4], $p1->[5]];
    #print "(for x) ";
    #printlist($p);
    push @out, $p;
  }
  my ($x1, $x2) = (max($p1->[0], $p2->[0]), min($p1->[1], $p2->[1]));
  return @out unless ($x1 < $x2);
  for my $y (intervaldiff($p1->[2], $p1->[3], $p2->[2], $p2->[3])) {
    my $p = [$x1, $x2, @$y, $p1->[4], $p1->[5]];
    #print "(for y) ";
    #printlist($p);
    push @out, $p;
  }
  my ($y1, $y2) = (max($p1->[2], $p2->[2]), min($p1->[3], $p2->[3]));
  return @out unless ($y1 < $y2);
  for my $z (intervaldiff($p1->[4], $p1->[5], $p2->[4], $p2->[5])) {
    my $p = [$x1, $x2, $y1, $y2, @$z];
    #print "(for z) ";
    #printlist($p);
    push @out, $p;
  }
  #print " -> ";
  #printlist @out;
  return @out;
}

sub volume {
  my $p = shift;
  return ($p->[1]-$p->[0]) * ($p->[3]-$p->[2]) * ($p->[5]-$p->[4]);
}

while (<>) {
  print;
  chomp;
  my @p = m{(on|off) x=(-?\d+)..(-?\d+),y=(-?\d+)..(-?\d+),z=(-?\d+)..(-?\d+)};
  my $state = (shift @p eq 'on');
  $p[1]++; $p[3]++; $p[5]++;
  @A = map {prismdiff($_, \@p)} @A;
  if ($state) {
    push @A, \@p;
  }
  #out (sum(map {volume($_)} @A));  
  #say "TOTAL LENGTH = ", scalar(@A);
}

out (sum(map {volume($_)} @A));