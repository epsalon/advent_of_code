#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
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
# input arr, row, col, neigh_arr
# returns array of [row, col, value]
sub neigh {
  my $arr = shift;
  my $row = shift;
  my $col = shift;
  my $neigh = shift;
  my $rows = @$arr;
  my $cols = @{$arr->[$row]};
  my @out;
  for my $pair (@$neigh) {
    my ($rd, $cd) = @$pair;
    my ($nr, $nc) = ($row + $rd, $col + $cd);
    next if $nr < 0;
    next if $nc < 0;
    next if $nr >= $rows;
    next if $nc >= $cols;
    push @out, [$nr, $nc, $arr->[$nr][$nc], "$nr,$nc"];
  }
  return @out;
}

# Orthogonal
sub oneigh {
  return neigh(@_, [[-1,0], [1, 0], [0, -1], [0, 1]]);
}

# All neighbors
sub aneigh {
  return neigh(@_, [
    [-1, -1], [-1, 0], [-1, 1],
    [ 0, -1],          [ 0, 1],
    [ 1, -1], [ 1, 0], [ 1, 1]]);
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

sub astar {
  my ($start, $end, $neigh, $h) = @_;
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

sub my_astar {
  my $A = shift;
  my $rows = @$A;
  my $cols = @{$A->[0]};

  my $start = "0,0";
  my $end = ($rows - 1). "," . ($cols - 1);

  my $neigh = sub {
    my $val = shift;
    my ($r, $c) = split(',', $val);
    return map {[$_->[3], $_->[2]]} oneigh($A, $r, $c);
  };

  my $h = sub {
    my $node = shift;
    my ($r, $c) = split(',', $node);
    return $rows + $cols - $r - $c - 2;
  };

  return astar($start, $end, $neigh, $h);
}

my @A;

while (<>) {
  chomp;
  last unless $_;
  push @A, [split('')];
}

out (my_astar(\@A));

for my $r (@A) {
  my @or = @$r;
  for my $i (1..4) {
    push @$r, (map {($_ + $i)%9 || 9} @or);
  }
}

my @OA = @A;

for my $i (1..4) {
  for my $r (@OA) {
    push @A, [(map {($_ + $i)%9 || 9} @$r)];
  }
}


out (my_astar(\@A));
