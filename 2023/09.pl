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

my $sumA=0;
my $sumB=0;

while (<>) {
  chomp;
  last unless $_;

  my @n = split(' ');
  my @r;
  my @e;
  while (notall {!$_} @n) {
    my @b;
    push @r, $n[0];
    push @e, $n[-1];
    my $x = shift(@n);
    while (@n) {
      my $y = shift(@n);
      push @b, ($y - $x);
      $x=$y;
    }
    @n = @b;
  }
  my $sg = 1;
  for my $rr (@r) {
    $sumB += $sg*$rr;
    $sg = -$sg;
  }
  $sumA+=sum(@e);
}

out ($sumA);
out ($sumB);
