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
  push @I, $_;
}

out(mix(1,@I));

for my $el (@I) {
  $el*=811589153;
}

out(mix(10,@I));

sub mix {
  my $niter = shift;
  my @A = @_;
  my @B = (0..$#A);
  for my $l (1..$niter) {
    for my $i (0..$#A) {
      my $x;
      for my $j (0..$#A) {
        if ($B[$j] == $i) {
          $x = $j; last;
        }
      }
      my $el = splice(@A,$x,1);
      my $dest = ($x + $el) % @A;
      splice(@A,$dest,0,$el);
      splice(@B,$x,1);
      splice(@B,$dest,0,$i);
    }
  }

  my $z;

  for my $i (0..$#A) {
    unless ($A[$i]) {
      $z = $i; last;
    }
  }

  my $sum=0;
  $z += 1000;
  $z %= @A;
  $sum += $A[$z];
  $z += 1000;
  $z %= @A;
  $sum += $A[$z];
  $z += 1000;
  $z %= @A;
  $sum += $A[$z];

  return $sum;
}
