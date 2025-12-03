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

$_=<>;
chomp;

my @ranges = split(/,/);
my @vs;

for my $x (@ranges) {
  $x =~ /^(\d+)-(\d+)$/;
  push @vs, $1-1, $2;
}

my @ovs = nsort(@vs);

my $lastval = $ovs[-1];
my $maxlen = length($lastval);

my %seen;

for my $reps (2..$maxlen) {
  my @vs=@ovs;
  my $flag=0;
  my $nv = shift(@vs);

  OUT: for my $l (1..$maxlen) {
    next if ($l % $reps);
    my $lo = "1" . ("0" x ($l/$reps - 1));
    my $hi = "9" x ($l/$reps);
    for my $v ($lo..$hi) {
      my $vv = "$v" x $reps;
      while ($nv < $vv) {
        last OUT unless @vs;
        $flag=1-$flag;
        $nv=shift(@vs);
      }
      $sum+=$vv if $flag && !$seen{$vv};
      $seen{$vv}++;
    }
  }
  if ($reps == 2) {
    out ($sum);
  }
}

out ($sum);
