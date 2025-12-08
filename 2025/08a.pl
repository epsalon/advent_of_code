#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use Math::Utils qw(:utility !log10);    # Useful functions

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my %H;
my $sum=0;

#my $grid = Grid::Dense->read();

while (<>) {
  chomp;
  last unless $_;
  push @A, [split(',')];
  $H{$#A}=$#A;
}

my @d;

for my $i (0..$#A-1) {
  for my $j ($i+1..$#A) {
    my ($x1,$y1,$z1) = @{$A[$i]};
    my ($x2,$y2,$z2) = @{$A[$j]};
    my $d = sqrt(($x1-$x2)*($x1-$x2) + ($y1-$y2)*($y1-$y2) + ($z1-$z2)*($z1-$z2));
    push @d, [$d, $i, $j];
  }
}

@d=sort {$a->[0] <=> $b->[0]} @d;

sub find {
  my $x = shift;
  while ($x != $H{$x}) {
    $x = $H{$x};
  }
  return $x;
}

my $i=1;
while ($i < 1000) {
  my $x = shift @d;
  my ($d,$a,$b) = @$x;
  my $va = find($a);
  my $vb = find($b);
  say "a=$a b=$b d=$d va=$va vb=$vb";
  say "A=",join(',', @{$A[$a]}), " B=",join(',', @{$A[$b]});
  $i++;
  if ($va != $vb) {
    $H{$vb}=$va;
    say " --set";
  }
}

my %cnt;

for my $j (0..$#A) {
  $cnt{find($j)}++;
}
say "i=$i", " ccnt=",scalar(%cnt);
dbg(\%cnt);

my @cnts = nsort(values(%cnt));

$sum=$cnts[-1] * $cnts[-2] * $cnts[-3];
out ($sum);
