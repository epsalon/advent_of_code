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
  my $cols = max(map {scalar(@$_)} @$arr);
  print "$rows $cols\n";
  for my $row (@$arr) {
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

my %G;

ROW: while(<>) {
  chomp;
  m{^(\w+)-(\w+$)} or die;
  push @{$G{$1}}, $2;
  push @{$G{$2}}, $1;
}

sub scan {
  my $st = shift;
  my $visited = shift;
  my $sc = shift;
  return 1 if ($st eq 'end');
  if ($visited->{$st} && $st =~ /[a-z]+/go) {
    return 0 if $sc;
    return 0 if ($st eq 'start' || $st eq 'end');
    $sc = 1;
  }
  my @n = @{$G{$st} || []};
  my $sum = 0;
  my %nviz = %$visited;
  $nviz{$st}++;
  for my $n (@n) {
    $sum += scan($n,\%nviz, $sc);
  }
  return $sum;
}

out (scan('start', {}, 1));
out (scan('start', {}, 0));
