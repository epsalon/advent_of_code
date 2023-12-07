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
  $h =~ tr/AKQJT/EDC1B/;
  my $s="";
  for my $j (split('', $h)) {
    my $x = $h;
    $x =~ s/1/$j/g;
    my $ss=score($x);
    $s = $ss if ($ss gt $s);
  }
  return "$s$h";
}

sub hscore {
  my $h=shift;
  $h =~ tr/AKQJT/EDCBA/;
  return score($h)."$h";
}

sub score{
  my %H;
  for my $x (split('', shift)) {
    $H{$x}++;
  }
  return reverse(sprintf("%05s",join('',nsort([values %H]))));
}

memoize(\&score);
memoize(\&hscore);
memoize(\&jscore);

sub getsum {
  my $sum;
  for my $i (0..$#_) {
    $sum += ($i+1) * $_[$i][1];
  }
  return $sum;
}

my @A;
while (<>) {
  chomp;
  push @A, [split()];
}

@A = sort {hscore($a->[0]) cmp hscore($b->[0])} @A;
say (getsum(@A));
@A = sort {jscore($a->[0]) cmp jscore($b->[0])} @A;
say (getsum(@A));
