#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max/;
use Math::Cartesian::Product;
use Math::Complex;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my %P1 = qw/) 3 ] 57 } 1197 > 25137/;
my %P2 = qw/( 1 [ 2 { 3 < 4/;

my $sum;
my @s2;
ROW: while (<>) {
  chomp;
  while (s/(\<\>|\{\}|\(\)|\[\])//go) {};
  if (/([\>\]\}\)])/) {
    $sum += $P1{$1};
  } else {
    my $s=0;
    for my $c (reverse(split(''))) {
      $s*=5; $s+=$P2{$c};
    }
    push @s2,$s;
  }
}

out($sum);
@s2 = sort {$a <=> $b} @s2;
out($s2[@s2/2]);