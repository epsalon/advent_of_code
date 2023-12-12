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
# use POSIX;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}

my @R;
my @C;
my $i=0;
while (<>) {
  chomp;
  while (/#/g) {
    push @R, $i;
    push @C, pos;
  }
  $i++;
}

@C = sort {$a <=> $b} @C;

for my $scale (2, 1e6) {
  my $sum;
  for my $A (\@R, \@C) {
    my @A = @$A;
    my $n = @A;
    my $p = shift @A;
    while (@A) {
      my $s = ($n - @A) * @A; # Scale factor
      my $c = shift @A;       # Current value
      my $d = ($c-$p);        # Delta from prev
      $p = $c;                # Reset prev
      if ($d > 1) {           # Adjust for expansion
        $d += ($scale - 1) * ($d - 1);
      }
      $sum += $d * $s;
    }
  }
  out($sum);
}
