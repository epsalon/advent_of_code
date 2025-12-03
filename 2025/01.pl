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
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my %H;
my $x=50;
my $sum=0;

#my $grid = Grid::Dense->read();

while (<>) {
  chomp;
  last unless $_;
  m{^([LR])(\d+)$}o or die;
  my $v=$2;
  my $d=($1 eq 'L' ? -1 : 1);
  while ($v) {
    $v--;
    $x+=$d;
    $x%=100;
    $sum++ unless $x;
  }
  print "$_ $x $sum\n";
}

$sum++ unless $x;

out ($sum);
