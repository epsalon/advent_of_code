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

sub nextval {
  my @n = @_;
  my @r;
  while (any {$_} @n) {
    my @b;
    push @r, $n[-1];
    my $x = shift(@n);
    for my $a (@n) {
      ($x, $a) = ($a, $a-$x);
    }
  }
  return sum(@r);
}

my $sumA=0;
my $sumB=0;

while (<>) {
  chomp;
  last unless $_;

  my @n = split(' ');
  $sumA+=sum(nextval(@n));
  $sumB+=sum(nextval(reverse(@n)));
}

out ($sumA);
out ($sumB);
