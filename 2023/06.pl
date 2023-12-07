#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
#use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use POSIX;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}

sub solve {
  my ($t, $d) = @_;
  my $delta = sqrt($t*$t/4 - $d);
  my $s1 = floor($t/2 - $delta);
  my $s2 = ceil($t/2 + $delta);
  return $s2-$s1-1;
}

my @t=<>=~/\d+/go;
my @d=<>=~/\d+/go;
out(product(map {solve(@$_)} zip(\@t,\@d)));
out(solve(join('',@t), join('',@d)));
