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
my %c;

for my $f (@f) {
  $c{$f}++;
}

for my $d (0..255) {
  $c{$d+9}+=$c{$d}||0;
  $c{$d+7}+=$c{$d}||0;
  delete $c{$d};
  out sum(values %c) if ($d == 79);
}

out sum(values %c);
