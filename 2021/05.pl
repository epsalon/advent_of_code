#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;
use Math::Complex;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my @grid;
my $sum;

while (<>) {
  chomp;
  m{(\d+),(\d+) -> (\d+),(\d+)}o or die;
  my ($a,$b,$c,$d) = ($1,$2,$3,$4);
  my $xd = $c <=> $a;
  my $yd = $d <=> $b;
  my ($x, $y) = ($a, $b);
  if ($grid[$x][$y]++ == 1) {
    $sum++;
  }
  while ($x != $c || $y != $d) {
    $x+=$xd; $y+=$yd;
    if ($grid[$x][$y]++ == 1) {
      $sum++;
    }
  }
}

out($sum);