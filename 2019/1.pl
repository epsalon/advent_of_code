#!/usr/bin/perl -w
use strict;

my $sum = 0;

while (<>) {
  chomp;
  my $fuel = int($_/3)-2;
  while ($fuel > 0) {
      $sum += $fuel;
      $fuel = int($fuel/3) - 2;
  }
}

print "$sum\n";
