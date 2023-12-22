#!/usr/bin/perl -w
use strict;
use feature 'say';

BEGIN {push @INC, "../lib";}
use AOC ':all';

$AOC::DEBUG_ENABLED=1;
$|=1;

my @bricks;

# Read input, calcualte cover
while (<>) {
  chomp;
  last unless $_;
  my @cover;
  my($a,$b) = split('~');
  my @a = split(',', $a);
  my @b = split(',', $b);
  for my $i ($a[0]..$b[0]) {
    for my $j ($a[1]..$b[1]) {
      push @cover, "$i$;$j";
    }
  }
  my ($min,$max) = ($a[2] < $b[2] ? ($a[2], $b[2]) : ($b[2], $a[2]));
  push @bricks,[$min,$max,@cover];
}

# Sort by bottom of brick
@bricks = sort {$a->[0] <=> $b->[0]} @bricks;

my @support_count;
my @supported; # supported {x} = list of bricks that x supports
my %G;

# Much more efficient drop, and calculate support
for my $bi (0..$#bricks) {
  my $b = $bricks[$bi];
  my ($min,$max,@cover) = @$b;
  # Drop
  DZ: for my $dz (1..$min) {
    my $z = $min-$dz;
    for my $c (@cover) {
      if (defined($G{$c,$z}) || !$z) {
        $min-=$dz-1; $max-=$dz-1;
        last DZ;
      }
    }
  }
  $bricks[$bi] = [$min,$max,@cover];
  # Update pit and supports
  my %sup;
  for my $c (@cover) {
    if (defined(my $base = $G{$c,$min-1})) {
      $sup{$base}++;
    }
    for my $z ($min..$max) {
      $G{$c,$z}=$bi;
    }
  }
  $support_count[$bi] = %sup;
  for my $s (keys(%sup)) {
    push @{$supported[$s]}, $bi;
  }
}

# Count drops
my $sumA;
my $sum;
for my $bi (0..$#bricks) {
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