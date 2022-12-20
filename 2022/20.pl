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
use Storable qw(dclone);

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

my @A;
my $sum=0;

my $i=0;
while (<>) {
  chomp;
  push @A, [$i++,$_*811589153];
}

for my $l (1..10) {
for my $i (0..$#A) {
  my $x;
  for my $j (0..$#A) {
    if ($A[$j][0] == $i) {
      $x = $j; last;
    }
  }
  my $el = splice(@A,$x,1);
  my $dest = ($x + $el->[1]) % @A;
  splice(@A,$dest,0,$el);
}
}

my $z;

for my $i (0..$#A) {
  unless ($A[$i][1]) {
    $z = $i; last;
  }
}


out(\@A);

$z += 1000;
$z %= @A;
$sum += $A[$z][1];
$z += 1000;
$z %= @A;
$sum += $A[$z][1];
$z += 1000;
$z %= @A;
$sum += $A[$z][1];

out ($sum);