#!/usr/bin/perl -w
use strict;
use feature 'say';

BEGIN {push @INC, "../lib";}
use AOC ':all';

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my $sum=0;

my %G;

# Read input, initialize grid
while (<>) {
  chomp;
  last unless $_;
  my($a,$b) = split('~');
  my @a = split(',', $a);
  my @b = split(',', $b);
  for my $i ($a[0]..$b[0]) {
    for my $j ($a[1]..$b[1]) {
      for my $k ($a[2]..$b[2]) {
        $G{$i,$j,$k} = @A;
      }
    }
  }
  push @A,[$a,$b];
}

# Initial fall
my $d=1;
while ($d) {
  $d=0;
  BLOOP: for my $bi (0..$#A) {
    my $b = $A[$bi];
    next unless $b;
    my @a = split(',' ,$b->[0]);
    my @b = split(',' ,$b->[1]);
    for my $i ($a[0]..$b[0]) {
      for my $j ($a[1]..$b[1]) {
        for my $k ($a[2]..$b[2]) {
          next BLOOP unless $k;
          next BLOOP if defined($G{$i,$j,$k-1}) && $G{$i,$j,$k-1} != $bi;
        }
      }
    }
    for my $i ($a[0]..$b[0]) {
      for my $j ($a[1]..$b[1]) {
        for my $k ($a[2]..$b[2]) {
          delete $G{$i,$j,$k};
        }
      }
    }
    $a[2]--; $b[2]--;
    $A[$bi] = [join(',',@a), join(',',@b)];
    for my $i ($a[0]..$b[0]) {
      for my $j ($a[1]..$b[1]) {
        for my $k ($a[2]..$b[2]) {
          $G{$i,$j,$k}=$bi;
        }
      }
    }
    $d=1;
  }
}

# Construct support graph
my @support_count;
my @supported; # supported {x} = list of bricks that x supports
BLOOP2: for my $bi (0..$#A) {
  my $b = $A[$bi];
  my @a = split(',' ,$b->[0]);
  my @b = split(',' ,$b->[1]);
  my %sup;
  for my $i ($a[0]..$b[0]) {
    for my $j ($a[1]..$b[1]) {
      for my $k ($a[2]..$b[2]) {
        next BLOOP2 unless $k;
        if (defined($G{$i,$j,$k-1}) && $G{$i,$j,$k-1} != $bi) {
          $sup{$G{$i,$j,$k-1}}++;
        }
      }
    }
  }
  die unless %sup;
  $support_count[$bi] = %sup;
  for my $s (keys(%sup)) {
    push @{$supported[$s]}, $bi;
  }
}

# Count drops
my $sumA;
for my $bi (0..$#A) {
  my $drops=0;
  my %support_loss;
  my @open = @{($supported[$bi] // [])};
  while (@open) {
    my $o = shift @open;
    if (++$support_loss{$o} == $support_count[$o]) {
      push @open, @{($supported[$o] // [])};
      $drops++;
    }
  }
  $sumA++ unless $drops;
  $sum+= $drops;
}

out($sumA);
out($sum);