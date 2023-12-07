#!/usr/bin/perl -w
use strict;
use feature 'say';
use Memoize;

# Numeric sort because sort defaults to lex
# returns new array
sub nsort {
  my $in = \@_;
  if (@$in == 1) {
    $in = $in->[0];
  }
  return sort {$a <=> $b} @$in;
}

sub jscore {
  my $h=shift;
  $h =~ tr/AKQJT/EDC1A/;
  return score($h)."$h";
}

sub hscore {
  my $h=shift;
  $h =~ tr/AKQJT/EDCBA/;
  return score($h)."$h";
}

sub score{
  my %H;
  my ($max,$amax) = (0);
  for my $x (split('', shift)) {
    $H{$x}++;
    if ($H{$x} > $max && $x ne "1") {
      $max = $H{$x};
      $amax = $x;
    }
  }
  if ($amax && $H{1}) {
    $H{$amax} += $H{1};
    delete $H{1};
  }
  return reverse(sprintf("%05s",join('',nsort([values %H]))));
}

sub getsum {
  my $sum;
  for my $i (0..$#_) {
    $sum += ($i+1) * $_[$i][1];
  }
  return $sum;
}

memoize('score');

my @A;
while (<>) {
  chomp;
  push @A, [split()];
}

@A = sort {hscore($a->[0]) cmp hscore($b->[0])} @A;
say (getsum(@A));
@A = sort {jscore($a->[0]) cmp jscore($b->[0])} @A;
say (getsum(@A));
