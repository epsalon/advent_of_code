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

my $grid = Grid::Dense->read();

my $c=0;
my $mr = $grid->rows()-1;

LOOP: while ($grid->bounds($mr,$c)) {
  my $nc=$c;
  my $op=$grid->at($mr,$c);
  my @vals;
  do {
    my $v='';
    for my $r (0..$mr-1) {
      $v.=$grid->at($r,$nc);
    }
    unless ($v =~ /^\s*$/) {
      push @vals, $v + 0;
    }
    $nc++;
  } while ($grid->bounds($mr,$nc) && $grid->at($mr,$nc) eq ' ');
  say "op = $op, vals=".join(',', @vals);
  if ($op eq '*') {
    $sum += product(@vals);
  } else {
    $sum += sum(@vals);
  }
  $c=$nc;
}

out ($sum);
