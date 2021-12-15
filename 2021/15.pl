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

my @A;

while (<>) {
  chomp;
  last unless $_;
  push @A, [split('')];
}

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

my $cols = @{$A[0]};

my @V = ([1, (0) x ($cols-1)], (undef) x ($#A));

equalize(\@V, 0);

my $cc = 1;
while ($cc) {
  $cc = 0;
  for my $r (0..$#A) {
    for my $c (0..$cols-1) {
      next unless ($r || $c);
      my $min = 999999999;
      my $cv = $A[$r][$c];
      for my $n (oneigh(\@V, $r, $c)) {
        my ($rn,$cn,$v) = @$n;
        $min = $v if ($v && ($v < $min));
      }
      $cc = 1 if (!$V[$r][$c] || $min + $cv < $V[$r][$c]);
      $V[$r][$c]=$min + $cv if $min < 999999999;
    }
  }
}

out $V[$#A][$cols - 1] - 1;