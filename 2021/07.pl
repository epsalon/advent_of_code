#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min/;
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
@f = sort {$a <=> $b} @f;

my $median = $f[@f/2];

out($median);

out(sum(map {abs($_ - $median)} @f));

my $mean = sum(@f) / @f;

$mean=int($mean);
my $meanb = $mean+1;
out($mean);

my $suma = sum(map {
  my $d = abs($_ - $mean);
  $d * ($d+1) / 2;
} @f);

my $sumb = sum(map {
  my $d = abs($_ - $meanb);
  $d * ($d+1) / 2;
} @f);

out min($suma,$sumb);
