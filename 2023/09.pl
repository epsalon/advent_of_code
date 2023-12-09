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
use Math::Polynomial;
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
my $sumA=0;
my $sumB=0;

while (<>) {
  chomp;
  last unless $_;

  my @n = split(' ');
  my $poly = Math::Polynomial->interpolate([0..$#n],\@n);
  $sumA+=sum(sprintf("%.0f",$poly->evaluate(scalar(@n))));
  $sumB+=sum(sprintf("%.0f",$poly->evaluate(-1)));
}

out ($sumA);
out ($sumB);
