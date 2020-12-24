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
my @A=split('','716892543');
my $MAX = 1e6;

#my $MAX = 9;

for my $i (10..$MAX) {
  push @A, $i;
}

my @N;
push @N, 'BAD';
$N[$A[$#A]] = $A[0];
for my $i (1..$#A) {
  $N[$A[$i-1]] = $A[$i];
}

my $ptr = $A[0];
sub cycle {
  my $pptr = $ptr;
  $ptr = $N[$ptr];
  return $pptr;
}

sub inlist {
  my ($el, $list) = @_;
  for my $x (@$list) {
    return 1 if ($x == $el);
  }
  return 0;
}

for my $i (1..1e7) {
  my $ccup = cycle;
  my @move;
  push @move, cycle();
  push @move, cycle();
  push @move, cycle();
  my $ncup = $ccup;
  do {
    $ncup--;
    $ncup = $MAX if ($ncup == 0);
  } while (inlist($ncup, \@move));
  ($N[$ncup], $N[$move[-1]], $N[$ccup]) = ($N[$ccup], $N[$ncup], $N[$move[-1]]);
}

out ($N[1] * $N[$N[1]]);
