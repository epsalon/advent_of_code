#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max/;
use Math::Cartesian::Product;
use Math::Complex;

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
    push @out, [$nr, $nc, $arr->[$nr][$nc]];
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

my %A;

ROW: while(<>) {
  chomp;
  last unless $_;
  m{(\d+),(\d+)}go;
  $A{"$1,$2"}++;
}

while (<>) {
  my $sum = 0;
  m{fold along ([xy])=(\d+)}o;
  my ($d,$n) = ($1, $2);
  my %O;
  for my $i (keys %A) {
    $i =~ m{(\d+),(\d+)}o;
    my ($x, $y) = ($1,$2);
    my ($sx, $sy) = (\$x, \$y);
    ($sx, $sy) = ($sy, $sx) if ($d eq 'y');
    if ($$sx > $n) {
      $$sx = 2*$n - $$sx;
    }
    unless ($O{"$x,$y"}++) {
      $sum++;
    }
  }
  out ($sum);
  %A = %O;
}

my $minx = min(map {m{(\d+),(\d+)}o; $1} keys(%A));
my $maxx = max(map {m{(\d+),(\d+)}o; $1} keys(%A));
my $miny = min(map {m{(\d+),(\d+)}o; $2} keys(%A));
my $maxy = max(map {m{(\d+),(\d+)}o; $2} keys(%A));
say "$minx $miny $maxx $maxy";
for my $y ($miny..$maxy) {
  for my $x ($minx..$maxx) {
    print ($A{"$x,$y"} ? '#' : '.');
  }
  print "\n";
}
