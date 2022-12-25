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
my $sum=0;

my %DIGITS = qw(1 1 2 2 0 0 - -1 = -2);
my %RDIGITS = qw(1 1 2 2 0 0 -1 - -2 =);

while (<>) {
  chomp;
  last unless $_;
  my @p = split('');
  my $v=0;
  for my $d (@p) {
    $v*=5;
    $v+=$DIGITS{$d};
  }
  $sum+=$v;
}

out ($sum);

my @res;
my $c=0;
while ($sum) {
  my $d = $sum % 5 + $c;
  if ($d > 2) {
    $d-=5;
    $c=1;
  } else {
    $c=0;
  }
  $sum/=5;
  $sum=int($sum);
  unshift(@res, $RDIGITS{$d});
}

out(join('',@res));