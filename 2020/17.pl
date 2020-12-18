#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

sub get_neigh {
  my ($x,$y,$z,$w) = @_;
  my @out;
  for my $xa ($x-1..$x+1) {
    for my $ya ($y-1..$y+1) {
      for my $za ($z-1..$z+1) {
        for my $wa ($w-1..$w+1) {
          next if ($x == $xa && $y == $ya && $z == $za && $w == $wa);
          push @out, "$xa,$ya,$za,$wa";
        }
      }
    }
  }
  return @out;
}

my $res = 0;

my %GRID;

my $y=0;
while(<>) {
  chomp;
  my $x=0;
  for my $c (split('')) {
    $GRID{"$x,$y,0,0"} = 1 if ($c eq '#');
    $x++;
  }
  $y++;
}


for my $i (0..5) {
  # iteration
  my %counts;
  for my $k (keys %GRID) {
    for my $n (get_neigh(split(/,/,$k))) {
      $counts{$n}+=2;
    }
    $counts{$k}++;
  }
  %GRID=();
  while (my ($k,$v) = each %counts) {
    if ($v >= 5 && $v <= 7) {
      $GRID{$k}++;
    }
  }
}

out scalar(%GRID);