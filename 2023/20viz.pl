#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use POSIX qw/floor ceil Inf log2/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my %H;
my $sum=0;

#while (my @R = arr_to_coords('#', read_2d_array())) {

say "digraph x {";
while (<>) {
  chomp;
  last unless $_;
  my ($f,$n,$r) = m{^(.)(\w+) -> (.+)$}o;
  say "$n [label=\"$f$n\"];";
  for my $x (split(', ', $r)) {
    say "$n -> $x";
  }
}
say "}";
