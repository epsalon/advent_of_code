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
sub equalize {
  my $arr = shift;
  my $fill = shift;
  my $rows = @$arr;
  my $cols = max(map {scalar(@$_)} @$arr);
  print "$rows $cols\n";
  for my $row (@$arr) {
    while (@$row < $cols) {
      push @$row, $fill;
    }
  }
}

# Find neighbors, returns array of [row, col, value]
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

my $sum;
my @s2;
ROW: while (<>) {
  chomp;
  my @r = split ('', $_);
  my @stack;
  for my $c (@r) {
    if ($c =~ m/[\(\[\{\<]/go) {
      $c =~ tr/\(\[\{\</\)\]\}\>/;
      push @stack, $c;
    } else {
      my $x = pop(@stack);
      if ($x ne $c) {
        $sum += 3 if $c eq ')';
        $sum += 57 if $c eq ']';
        $sum += 1197 if $c eq '}';
        $sum += 25137 if $c eq '>';
        next ROW;
      }
    } 
  }
  my $r=0;
  while (@stack) {
    my $x = pop(@stack);
    $r *= 5;
    $r += 1 if $x eq ')';
    $r += 2 if $x eq ']';
    $r += 3 if $x eq '}';
    $r += 4 if $x eq '>';
  }
  push @s2, $r;
}


out ($sum);
@s2 = sort {$a <=> $b} @s2;

out $s2[@s2/2];
