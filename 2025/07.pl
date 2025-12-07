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

my $start = <>;
chomp $start;
for my $i (0..length($start)) {
  if (substr($start,$i,1) eq 'S') {
    $H{$i}++;
  }
}

while (<>) {
  chomp;
  last unless $_;
  my @row = split('');
  my %H2;
  for my $k (keys %H) {
    if ($row[$k] eq '.') {
      $H2{$k}+=$H{$k};
    } else {
      $sum++;
      $H2{$k-1}+=$H{$k};
      $H2{$k+1}+=$H{$k};
    }
  }
  %H=%H2;
}

out ($sum);

out(sum(values %H));
