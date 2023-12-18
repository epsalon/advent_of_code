#!/usr/bin/perl -w
use strict;
no warnings qw/portable qw/;
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

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}

$|=1;

my %dir = qw/U -1,0 D 1,0 L 0,-1 R 0,1/;
for my $k (keys %dir) {
  my $v = $dir{$k};
  $dir{$k} = [split(',', $v)];
}

sub solve_area {
  my ($area, $perimeter) = (0,1);
  my ($r,$c) = (0,0);
  while (@_) {
    my $dir = shift;
    my $count = shift;
    my ($dr,$dc) = @$dir;
    $dr *= $count; $dc *= $count;
    my ($nr,$nc) = ($r+$dr,$c+$dc);
    $perimeter += $count/2;
    $area += ($c*$nr - $nc*$r)/2;
    ($r,$c)=($nr,$nc);
  }
  return abs($area) + $perimeter;
}

my (@p1, @p2);

while (<>) {
  chomp;
  last unless $_;
  my($adir,$acount,$bcounthex,$bdir) = m{(\w) (\d+) \(\#([\da-f]+)([0123])\)} or die;
  push @p1, $dir{$adir}, $acount;
  $bdir = ([0,1], [1,0], [0,-1], [-1,0])[$bdir];
  my $bcount = oct("0x$bcounthex");
  push @p2, $bdir, $bcount;
}

out (solve_area(@p1));
out (solve_area(@p2));
