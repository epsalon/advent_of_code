#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Storable qw(dclone);

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

my $sumA=0;
my $sumB=0;

my %L = qw/red 12 green 13 blue 14/;

while (<>) {
  chomp;
  last unless $_;
  m{^Game (\d+)}go;
  my $g = $1;
  my %H;
  while (m{(\d+) (\w+)}go) {
    $H{$2} = $1 if (!$H{$2} || $H{$2} < $1);
    $g = 0 if ($L{$2} < $1);
  }
  $sumA += $g;
  $sumB += product(values %H);
}

out ($sumA);
out ($sumB);
