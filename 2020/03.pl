#!/usr/bin/perl -w
use strict;

my @SLOPEX = (1,3,5,7,1);
my @SLOPEY = (1,1,1,1,2);
my @pos = (0,0,0,0,0);
my @count = (0,0,0,0,0);
my $row = 0;

while (<>) {
  chomp;
  my $width = length($_);
  for my $i (0..$#pos) {
    if ($row % $SLOPEY[$i] != 0) {
      next;
    }
    if (substr($_,$pos[$i],1) eq '#') {
      $count[$i]++;
    }
    $pos[$i] += $SLOPEX[$i];
    $pos[$i] %= $width;
  }
  $row++;
}

my $res = 1;
for my $c (@count) {
  $res *= $c;
}

print "$res\n";
