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

die "not centered" unless ($size == $sr*2+1 && $sr == $sc);

die "Target is not multiplier of size" unless $TARGET % $size == $sr;
my $multiplier = ($TARGET - $sr) / $size;

sub megagrid {
  my ($r,$c) = @_;
  $r %= $size; $c %= $size;
  return ($grid->at($r,$c) ne '#');
}
memoize('megagrid');

my @values;
my @open = "$sr,$sc";
my %closed0;
my %closed1;
for my $i (1..$sr + 2*$size) {
  dbg($i);
  my %nopen;
  my $closed = ($i&1?\%closed1:\%closed0);
  for my $o (@open) {
    $closed->{$o}++;
    my ($r,$c) = split(',', $o);
    for my $d ([1,0],[-1,0],[0,1],[0,-1]) {
      my ($nr,$nc) = ($r+$d->[0],$c+$d->[1]);
      next unless megagrid($nr,$nc);
      next if $closed0{"$nr,$nc"};
      next if $closed1{"$nr,$nc"};
      $nopen{"$nr,$nc"}++;
    }
  }
  @open = keys %nopen;
  my $count = ($i&1?%closed0:%closed1) + @open;
  push @values, $count if ($i % $size == $sr);
  out($count) if ($i == $PART1);
  dbg($count);
}

my $poly = Math::Polynomial->interpolate([0,1,2],\@values);
my $result = $poly->evaluate($multiplier);
out($result);
