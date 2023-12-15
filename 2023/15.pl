#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
# use POSIX;

BEGIN {push @INC, "../lib";}
use Grid::Dense;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}


sub hash {
  my $h=0;
  for my $c (split('', shift)) {
    $h+=ord($c);
    $h*=17;
    $h%=256;
  }
  return $h;
}

my @A;
for my $i (0..255) {push @A,[];}
my $sum=0;

$|=1;

while (<>) {
  chomp;
  last unless $_;
  LOOP: for my $s (split(',')) {
    $sum+=hash($s);
    if (my ($nk,$nv) = $s =~ /^(.*)=(\d+)$/) {
      my $box=$A[hash($nk)];
      for my $it (@$box) {
        my ($k,$v) = @$it;
        if ($k eq $nk) {
          $it = [$k, $nv];
          next LOOP;
        }
      }
      push @$box, [$nk,$nv];
    } elsif (my ($k) = $s =~ /^(.*)-$/) {
      my $box=$A[hash($k)];
      @$box = grep {$_->[0] ne $k} @$box;
    } else {
      die;
    }
  }
}
out($sum);

$sum=0;
for my $box (0..$#A) {
  for my $slot (0..$#{$A[$box]}) {
    $sum += ($box + 1) * ($slot + 1) * $A[$box][$slot][1];
  }
}
out ($sum);
