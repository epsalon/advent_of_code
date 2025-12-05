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
  m/^(\d+)-(\d+)$/o;
  push @A, [$1, 1];
  push @A, [$2+1, -1];
}

@A = sort {$a->[0] <=> $b->[0]} @A;

my @A2=@A;

dbg(\@A);

my @B;

while (<>) {
  chomp;
  last unless $_;
  push @B, $_;
}

@B = nsort(@B);

my $val=0;

while (@B) {
  my $b = shift @B;
  while (@A && ($b > $A[0][0])) {
    my $a = shift(@A);
    $val += $a->[1];
  }
  print "$b $val\n";
  $sum++ if ($val > 0);
}

out ($sum);

my $prev = 0;
$val=0;
$sum=0;
for my $a (@A2) {
  print "val=$val a[0]=".$a->[0]." prev=$prev\n";
  if ($val) {
    $sum+=$a->[0]-$prev;
  }
  $prev=$a->[0];
  $val+=$a->[1];
}
out ($sum);
