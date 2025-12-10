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
  my @l = split(',');
  push @A,\@l;
}

my @xs = uniq(nsort(map {$_->[0]} @A));
my @ys = uniq(nsort(map {$_->[1]} @A));

my %xm;
my %ym;

for my $i (0..$#xs) {
  $xm{$xs[$i]}=$i;
}
for my $i (0..$#ys) {
  $ym{$ys[$i]}=$i;
}

my $grid = Grid::Dense->from_string(scalar((("." x @xs) . "\n") x @ys));

my @B = map {[$xm{$_->[0]}, $ym{$_->[1]}]} @A;

my $f_y;

for my $i (0..$#B) {
  my $j = $i+1;
  $j = 0 if ($j == @B);
  my ($x1,$y1) = @{$B[$i]};
  unless ($x1) {
    $f_y=$y1;
  }
  my ($x2,$y2) = @{$B[$j]};
  if ($x1 > $x2) {
    ($x2,$x1) = ($x1,$x2);
  }
  if ($y1 > $y2) {
    ($y2,$y1) = ($y1,$y2);
  }
  for my $x ($x1..$x2) {
    for my $y ($y1..$y2) {
      $grid->set($x,$y,'X');
    }
  }
}

for my $b (@B) {
  my ($x,$y) = @{$b};
  $grid->set($x,$y,'#');
}

my %bhash = ('X', 1, '#', 1, ' ', 1);
my $f_x;

for my $x (0..$#xs) {
  if ($grid->at($x, $f_y) eq '.') {
    $f_x = $x;
    last;
  }
}

$grid->floodfill($f_x, $f_y,\%bhash, ' ');

my ($b1,$b2);

for my $a (0..$#B-1) {
  RECT: for my $b ($a+1..$#B) {
    my ($x1,$y1) = @{$B[$a]};
    my ($x2,$y2) = @{$B[$b]};
    if ($x1 > $x2) {
      ($x2,$x1) = ($x1,$x2);
    }
    if ($y1 > $y2) {
      ($y2,$y1) = ($y1,$y2);
    }
    for my $x ($x1..$x2) {
      for my $y ($y1..$y2) {
        if ($grid->at($x,$y) eq '.') {
          # say "skipped $x1 $y1 $x2 $y2";
          next RECT;
        }
      }
    }
    my $area=($xs[$x2]-$xs[$x1]+1) * ($ys[$y2]-$ys[$y1]+1);
    say "$x1 $y1 -- $x2 $y2 -- $area";
    if ($area > $sum) {
      $sum=$area;
      $b1=$a;$b2=$b;
    }
  }
}

$grid->print(@{$B[$b1]},@{$B[$b2]});

out ($sum);
