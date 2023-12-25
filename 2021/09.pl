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

my @a;

while (<>) {
  chomp;
  my @l = split('');
  @l = (9, @l, 9);
  push @a, \@l;
}

my $xx=@{$a[0]};
my @r = (9) x $xx;
unshift @a, \@r;
push @a, \@r;

sub basin {
  my ($r,$c, $x) = @_;
  return 0 if ($x->[$r][$c]);
  $x->[$r][$c]++;
  return 0 if ($a[$r][$c] == 9);
  my $sum = 1;
  $sum += basin($r-1,$c,$x);
  $sum += basin($r+1,$c,$x);
  $sum += basin($r,$c-1,$x);
  $sum += basin($r,$c+1,$x);
  return $sum;
}

my @basins;

my $sum;
for my $i (1..$#a-1) {
  for my $j (1..$xx-2) {
    my $c = $a[$i][$j];
    if ($c < $a[$i-1][$j] && $c < $a[$i+1][$j] && $c < $a[$i][$j-1] && $c < $a[$i][$j+1]) {
      $sum += $c+1;
      push @basins, basin($i,$j,[]);
    }
  }
}

out($sum);

@basins = sort {$a <=> $b} @basins;

out($basins[-1] * $basins[-2] * $basins[-3]);
