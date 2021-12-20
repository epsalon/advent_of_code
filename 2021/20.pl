#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

# Read code
$_ = <>;
chomp;
my @CODE = map {$_ eq '#'} split('');

# Read initial position
my @A;
my $r=0;
while (<>) {
  chomp;
  my $c=0;
  for my $v (split('')) {
    push @A, "$r,$c" if $v eq '#';
    $c++;
  }
  $r++;
}

# Neighbors, initialize background
my @NARR = reverse([-1, -1], [-1, 0], [-1, 1], [ 0, -1], [ 0, 0], [ 0, 1], [ 1, -1], [ 1, 0], [ 1, 1]);
my $bg = 0;

# Enchancement steps
for my $i (1..50) {
  my %H;
  my $nbg = $CODE[$bg?-1:0];

  # Collect the relevant 3x3 binary values based on neighbors
  for my $k (@A) {
    my ($r,$c) = split(',', $k);
    for my $n (0..$#NARR) {
      my ($dx, $dy) = @{$NARR[$n]};
      my ($nr, $nc) = ($r-$dx, $c-$dy);
      $H{"$nr,$nc"} |= 1 << $n;
    }
  }
  # Create the output list of non-bg values
  @A=();
  while (my ($k,$val) = each %H) {
    # need to flip the code if the bg is reversed
    $val = (~$val & 511) if $bg;
    # Only set the output if it's different from the background
    if ($CODE[$val] ^ $nbg) {
      push @A, $k;
    }
  }
  $bg=$nbg;
  out (scalar @A) if ($i==2); # Part 1
}

out (scalar @A);