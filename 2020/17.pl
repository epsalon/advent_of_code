#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

sub get_neigh {  # includes self
  my @p = map {[$_-1,$_,$_+1]} @_;
  my @out;
  cartesian {push @out, join(",", @_)} @p;
  return @out;
}

my $res = 0;
my %GRID;
my $y=0;
while(<>) {
  chomp;
  my $x=0;
  for my $c (split('')) {
    $GRID{"$x,$y,0,0"} = 1 if ($c eq '#');
    $x++;
  }
  $y++;
}


for my $i (0..5) {
  # iteration
  my %counts;
  for my $k (keys %GRID) {
    for my $n (get_neigh(split(/,/,$k))) {
      $counts{$n}+=2;
    }
    $counts{$k}--;
  }
  %GRID=();
  while (my ($k,$v) = each %counts) {
    if ($v >= 5 && $v <= 7) {
      $GRID{$k}++;
    }
  }
}

out scalar(%GRID);