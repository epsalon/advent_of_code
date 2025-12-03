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
  tr/LR/-+/;
  my $v=$_;
  $sum+=int(abs($v)/100);
  $v%=100;
  $v-=100 if ($_<0);
  $x+=$v;
  if ($x>=100) {
    $sum++;
    $x-=100;
  }
  if ($x<0) {
    $sum++;
    $x+=100;
  }
  print "$_ $v $x $sum\n";
}

$sum++ unless $x;

out ($sum);
