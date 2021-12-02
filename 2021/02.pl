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

my ($h,$a,$d) = 0;
my @A;

while (<>) {
    chomp;
    m{(\w)\w+ (\d+)}go;
    $h+=$2 if ($1 eq 'f');
    $d+=$a*$2 if ($1 eq 'f');
    $a+=$2 if ($1 eq 'd');
    $a-=$2 if ($1 eq 'u');
}

out $h*$d;