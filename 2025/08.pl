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
use Math::Utils qw(:utility !log10);    # Useful functions

BEGIN {push @INC, "../lib";}
use AOC ':all';
use UF;
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my @B;
my %H;
my $sum=0;

#my $grid = Grid::Dense->read();

while (<>) {
  chomp;
  last unless $_;
  push @A, [split(',')];
}

my $uf = new UF([0..$#A]);

my @d;

for my $i (0..$#A-1) {
  for my $j ($i+1..$#A) {
    my ($x1,$y1,$z1) = @{$A[$i]};
    my ($x2,$y2,$z2) = @{$A[$j]};
    my $d = ($x1-$x2)*($x1-$x2) + ($y1-$y2)*($y1-$y2) + ($z1-$z2)*($z1-$z2);
    push @d, [$d, $i, $j];
  }
}

@d=sort {$a->[0] <=> $b->[0]} @d;

my $i=1;
while ($i < @A) {
  my $x=shift @d;
  shift(@$x);
  my ($a,$b) = @$x;
  $i++ if ($uf->union($a,$b));
  if ($i == @A) {
      out($A[$a]->[0] * $A[$b]->[0]);
  }
}
