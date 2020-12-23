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

my $res = 0;

my @A=split('','716892543');

for my $i (10..1e6) {
  push @A, $i;
}

my %IDX;

for my $i (0..$#A) {
  $IDX{$A[$i]} = $i;
}

my $offset = 0;

for my $i (1..1e7) {
  say $i unless ($i % 1e6);
  my $ccup = shift @A;
  push @A, $ccup;
  $IDX{$ccup} = 1e6-1 + $offset;
  my @move = splice(@A,0,3);
  $offset+=4;
  my $found = 0;
  my $pcup = $ccup;
  while (!$found) {
    $ccup--;
    $ccup = 1e6 if ($ccup == 0);
    $found = $IDX{$ccup}-$offset + 1 unless $ccup == $move[0] || $ccup == $move[1] || $ccup == $move[2];
  }
  splice(@A,$found,0,@move);
  for my $i (0..$#move) {
    $IDX{$move[$i]} = 1e6 - 4 + $i + $offset;
  }
}

my $loc = $IDX{1} - $offset;

$res = $A[$loc+1] * $A[$loc+2];

out $res;