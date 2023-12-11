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
# use POSIX;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}

my @A;
my %rmap;
my $erow=0;

while (<>) {
  chomp;
  last unless $_;
  push @A, [split('')];
  if (/^\.+$/) {
    $erow++;
  } else {
    $rmap{$#A}=$erow;
  }
}

my %cmap;
my $ecol=0;
my @g;

for my $c (0..$#{$A[0]}) {
  my $emp = 1;
  for my $r (0..$#A) {
    if ($A[$r][$c] eq '#') {
      $emp = 0;
      push @g, [$r,$c];
    }
  }
  if ($emp) {
    $ecol++;
  } else {
    $cmap{$c}=$ecol;
  }
}

sub dist {
  my $aval = shift;
  my $a = shift;
  my $b = shift;
  my $e = shift;
  ($a, $b) = ($b, $a) if ($b < $a);
  return $b-$a + ($aval-1) * ($e->{$b} - $e->{$a});
}

sub totdist {
  my $aval=shift;
  my $sum = 0;
  for my $i (0..$#g-1) {
    for my $j ($i+1..$#g) {
      my $d = dist($aval,$g[$i][0],$g[$j][0],\%rmap)+
              dist($aval,$g[$i][1],$g[$j][1],\%cmap);
      $sum += $d;
    }
  }
  return $sum;
}

out (totdist(2));
out (totdist(1e6));
