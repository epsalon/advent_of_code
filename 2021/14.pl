#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max/;
use Math::Cartesian::Product;
use Math::Complex;
use Hash::MultiKey;

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

my %H;

my $w = <>;
chomp $w;
my @W = split('', $w);
my %W;
for my $x (0..$#W-1) {
  $W{$W[$x] . $W[$x+1]}++;
}
<>;

sub outW {
  my %F = ($W[0], 1, $W[-1], 1);
  while (my ($k,$v) = each %W) {
    my ($a,$b) = split('', $k);
    $F{$a}+=$v;
    $F{$b}+=$v;
  }
  my @F = nsort(values %F);
  out (($F[-1] - $F[0])/2);
}

ROW: while(<>) {
  chomp;
  last unless $_;
  m{(\w+) -> (\w+)}go or die;
  $H{$1} = $2;
}

for my $i (1..40) {
  my %W2;
  while (my ($k,$v) = each %W) {
    my ($a,$b) = split('', $k);
    my $m = $H{$k};
    $W2{"$a$m"}+=$v;
    $W2{"$m$b"}+=$v;
  }
  %W = %W2;
  outW if ($i == 10);
}

outW;