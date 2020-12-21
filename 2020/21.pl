#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my $res = 0;
my %ALL;
my @INP;
while(<>) {
  chomp;
  m{^([\w\s]+)\(contains ([\w\s,]+)\)$}o or die;
  my @ilist = split(' ', $1);
  my @alist = split(/,\s+/, $2);
  for my $a (@alist) {
    $ALL{$a}++;
  }
  my %ahash = map {$_ => 1} @alist;
  push @INP, [\@ilist, \%ahash];
}

my %IALL;
for my $l (@INP) {
  my ($ilist, $ahash) = @$l;
  for my $i (@$ilist) {
    for my $a (keys %ALL) {
      $IALL{$i}{$a}++ unless $ahash->{$i};
    }
  }
}

print Dumper(\%IALL);

for my $v (values %IALL) {
  $res++ if (%$v == %ALL)
}

out ($res);
