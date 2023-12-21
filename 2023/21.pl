#!/usr/bin/perl -w
use strict;
use feature 'say';
use Memoize;
use Math::Polynomial;

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=0;
my $PART1 = 64;
my $TARGET = 26501365;

my $grid = Grid::Dense->read();
my $size = $grid->rows();
die "not square" unless $size == $grid->cols();

my ($sr,$sc);
$grid->iterate(sub {
  my ($r,$c,$v) = @_;
  if ($v eq 'S') {
    ($sr,$sc) = ($r,$c);
  }
});

my $modulus = $TARGET % $size;
my $multiplier = ($TARGET - $modulus) / $size;

my @values;
my @open = "$sr,$sc";
my @closed;
for my $i (1..$modulus + 2*$size) {
  dbg($i);
  my %nopen;
  my $closed = $closed[$i&1];
  for my $o (@open) {
    $closed->{$o}++;
    my ($r,$c) = split(',', $o);
    for my $d ([1,0],[-1,0],[0,1],[0,-1]) {
      my ($nr,$nc) = ($r+$d->[0],$c+$d->[1]);
      next if $grid->at($nr % $size,$nc % $size) eq '#';
      next if $closed[0]{"$nr,$nc"};
      next if $closed[1]{"$nr,$nc"};
      $nopen{"$nr,$nc"}++;
    }
  }
  @open = keys %nopen;
  my $count = %{$closed[1-$i&1]} + @open;
  if ($i % $size == $modulus) {
    push @values, $count;
    # Verify that the input allows all possible values at cycle point
    for my $j (0..$i) {
      for my $c ([$j,$i-$j],[-$j,$i-$j],[-$j,$j-$i],[$j,$j-$i]) {
        my ($cr,$cc) = ($sr+$c->[0], $sc+$c->[1]);
        die "Not complete at ($cr,$cc)" unless $nopen{"$cr,$cc"};
      }
    }
  }
  out($count) if ($i == $PART1);
  dbg($count);
}

my $poly = Math::Polynomial->interpolate([0,1,2],\@values);
my $result = $poly->evaluate($multiplier);
out($result);
