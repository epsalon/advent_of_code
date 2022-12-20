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

my @I;

my $i=0;
while (<>) {
  chomp;
  push @I, [$i++,$_];
}

out(mix(1,@I));

for my $el (@I) {
  $el->[1]*=811589153;
}

out(mix(10,@I));

sub mix {
  my $niter = shift;
  my @A = @_;
  for my $l (1..$niter) {
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

  my $sum=0;
  $z += 1000;
  $z %= @A;
  $sum += $A[$z][1];
  $z += 1000;
  $z %= @A;
  $sum += $A[$z][1];
  $z += 1000;
  $z %= @A;
  $sum += $A[$z][1];

  return $sum;
}