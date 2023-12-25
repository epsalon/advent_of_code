#!/usr/bin/perl -w
use strict;

my ($min, $max, $sum) = (1025, -1, 0);

while (<>) {
  chomp;
  tr/FLRB/0011/;
  my $v = oct("0b$_");
  if ($v < $min) {
      $min = $v;
  }
  if ($v > $max) {
      $max = $v;
  }
  $sum += $v;
}

print "$min $max $sum\n";

my $myseat = ($max + $min) * ($max - $min + 1) / 2 - $sum;
print "$myseat\n";
