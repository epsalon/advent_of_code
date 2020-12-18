#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

sub myeval {
  my $x = shift;
  while ($x=~s{\(([^\(\)]+)\)}{myeval($1)}goe) {};
  my @subs = map {eval($_)} split(/ \* /,$x);
  my $pr = 1;
  for my $s (@subs) {
    $pr *= $s;
  }
  return $pr;
}

my $res = 0;
while(<>) {
  chomp;
  $res += myeval($_);
}

out $res;