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

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}


sub ucount {
  my ($r, $p1, $p2, $s1, $s2) = @_;
  my ($u1, $u2);
  unless ($r) {
    $s1+=$p1;
    if ($s1 >= 21) {
      return (1, 0);
    }
    ($u2, $u1) = ucount(3, $p2, $p1, $s2, $s1);
    return ($u1, $u2);
  }
  my $cp1=$p1;
  for my $d (1..3) {
    $p1 = $cp1+$d;
    $p1 = $p1 % 10 || 10;
    my ($du1, $du2) = ucount($r-1, $p1, $p2, $s1, $s2);
    $u1 += $du1;
    $u2 += $du2;
  }
  return ($u1, $u2);
}

memoize('ucount');

my $p1 = 10;
my $p2 = 3;

out(max(ucount(3,4,8,0,0)));
out(max(ucount(3,10,3,0,0)));

my ($s1,$s2) = (0,0);
my $d=1;

while ($s1 < 1000 && $s2 < 1000) {
  $p1 += ($d++) % 100 || 100;
  $p1 += ($d++) % 100 || 100;
  $p1 += ($d++) % 100 || 100;
  $p1 = $p1 % 10 || 10;
  $s1 += $p1;
  last if ($s1 >= 1000);
  $p2 += ($d+1)*3; $d+=3;
  $p2 = $p2 % 10 || 10;
  $s2 += $p2;
}

out(($d-1) * min($s1,$s2));