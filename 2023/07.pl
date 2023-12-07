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
  my $h = shift;
  my %H;
  for my $x (split('', $h)) {
    $H{$x}++;
  }
  my @v = values %H;
  @v = nsort(\@v);
  if ($v[-1]==5) {
    return "9";
  }
  if ($v[-1]==4) {
    return "8";
  }
  if ($v[-1]==3 && $v[-2]==2) {
    return "7";
  }
  if ($v[-1]==3) {
    return "6";
  }
  if ($v[-1]==2 && $v[-2]==2) {
    return "5";
  }
  if ($v[-1]==2) {
    return "4";
  }
  return "0";
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
  last unless $_;
  push @A, [split()];
}

@A = sort {hscore($a->[0]) cmp hscore($b->[0])} @A;
say (getsum(@A));
@A = sort {jscore($a->[0]) cmp jscore($b->[0])} @A;
say (getsum(@A));
