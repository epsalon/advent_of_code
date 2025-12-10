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

sub bitcount {
  my $v = shift;
  my $c=0;
  while ($v) {
    $v &= $v-1;
    $c++;
  }
  return $c;
}

while (<>) {
  chomp;
  last unless $_;
  m{\[(.+)\]\s+(.+?)\s+\{.+\}}o;
  my $t = $1;
  $t =~ tr/.#/01/;
  $t = bin2dec(scalar(reverse($t)));
  my @b = map {/\((.+)\)/;sum(map {1 << $_} split(',',$1))} split(' ',$2);
  #dbg($t);
  #dbg(\@b);
  my $minbit=99;
  for my $i (0..(1 << $#b+1)-1) {
    my $v=0;
    my @bs = split('',sprintf("%0".($#b+1)."s",dec2bin($i)));
    #dbg (\@bs);
    for my $j (0..$#bs) {
      if ($bs[$j]) {
        $v ^= $b[$j];
      }
    }
    #say "i=$i v=$v t=$t";
    if ($v == $t) {
      say "found $v at $i";
      my $bits = bitcount($i);
      if ($bits < $minbit) {
        $minbit=$bits;
      }
    }
  }
  dbg("minbit = ".$minbit);
  $sum += $minbit;
}

out ($sum);
