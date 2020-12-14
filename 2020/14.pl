#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
#use bigint;
no warnings;

my %MEM;

my $mask0;
my $mask1;
my @XLIST;

while (<>) {
  chomp;
  if (m{^mask = ([01X]+)$}o) {
    my $mask = $1;
    my $m1 = $mask;
    $m1 =~ tr/X/0/;
    $mask1 = oct("0b$m1");
    my $m0 = $mask;
    $m0 =~ tr/0X/10/;
    $mask0 = oct("0b$m0");
    my @mask = split('', $mask);
    @XLIST=();
    for my $i (0..$#mask) {
      if ($mask[$i] eq 'X') {
        push @XLIST, 35 - $i;
      }
    }
  } elsif (m{^mem\[(\d+)\] = (\d+)$}o) {
    my ($addr, $val) = ($1,$2);
    $addr |= $mask1;
    $addr &= $mask0;
    my $XCOUNT = scalar(@XLIST);
    for my $i (0 .. (1 << $XCOUNT) - 1) {
      my $bits = $i;
      my $a = $addr;
      for my $b (@XLIST) {
        $a |= ($bits & 1) << $b;
        $bits >>= 1;
      }
      $MEM{$a} = $val;
    }
  }
}

my $sum = 0;
while (my ($k,$v) = each(%MEM)) {
  $sum += $v;
}

say $sum;