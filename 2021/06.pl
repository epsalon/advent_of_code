#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;
use Math::Complex;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

$_=<>;
chomp;

my @f = split(/,/);
my @c;

for my $f (@f) {
  $c[$f]++;
}

for my $d (1..256) {
  my $n = shift @c || 0;
  $c[8]+=$n;
  $c[6]+=$n;
  out sum(@c) if ($d == 80);
}

out sum(@c);
