#!/usr/bin/perl -w
use strict;
use Math::Complex;

my %DIRS = ('N', -1, 'S', 1, 'E', i, 'W', -i);
my $dir = -1 + 10 * i;
my $pos = 0;

while (<>) {
  /^([NEWSLRF])(\d+)/ or die;
  my ($cmd,$val) = ($1,$2);
  if ($cmd eq 'F') {
    $pos+=$dir * $val;
  } elsif ($DIRS{$cmd}) {
    $dir+=$DIRS{$cmd} * $val;
  } else {
    if ($cmd eq 'R') {
      $val = -$val;
    }
    $dir *= i ** ($val/90);
  }
}

print abs(Re($pos)) + abs(Im($pos)),"\n";