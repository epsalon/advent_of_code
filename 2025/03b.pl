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
my $sum=0;

#my $grid = Grid::Dense->read();

sub f {
  my $n=shift;
  my $start=shift;
  my $max=0;
  my $a;
  for my $m (0..$#A-$n-$start) {
    my $id=$#A-$n-$m;
    if ($A[$id] >= $max) {
      $max=$A[$id];
      $a=$id;
    }
  }
  if ($n) {
    return $max . f($n-1, $a+1);
  } else {
    return $max;
  }
}

while (<>) {
  chomp;
  last unless $_;
  @A=split('');
  $sum+=f(11,0);
}

out ($sum);
