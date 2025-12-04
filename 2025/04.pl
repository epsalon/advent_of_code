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

my %H;
my $sum=0;

my $grid = Grid::Dense->read();

my $psum;
do {
  my @A;
  $psum = $sum;
  $grid->iterate(sub {
    my $r=shift; my $c=shift; my $v=shift;
    my $t=0;
    return unless ($v eq '@');
    my @n = $grid->aneigh($r,$c);
    for my $v (@n) {
      my $c = $v->[2];
      $t++ if $c eq '@';
    }
    if ($t < 4) {
      $sum++;
      push @A,[$r,$c];
    }
  });
  print "psum=$psum sum=$sum\n";
  for my $x (@A) {
    $grid->set(@$x, 'x');
  }
  $grid->print(@A) if ($psum!=$sum);
} until ($psum==$sum);

out ($sum);
