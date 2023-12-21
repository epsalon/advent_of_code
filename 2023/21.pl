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
use Math::Utils qw(:utility !log10);    # Useful functions

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

# A = (x-65)/131 = 20238
# ((A+.5)^2-.25) * total - A * in' + (A+1) * in


my @A;
my %H;
my $sum=0;

my $grid = Grid::Dense->read();
my $sgrid = Grid::Sparse->new({});

$grid->iterate(sub {
  my ($r,$c,$v) = @_;
  my ($rd,$cd) = (0,0);
  #for my $rd (-131,0,131) {
  #  for my $cd (-131,0,131) {
      $sgrid->set($r+$rd-65,$c+$cd-65,$v);
  #  }
  #}
});


#my @open = "65,65";
#for my $i (1..131+65) {
#  my %nopen;
#  for my $o (@open) {
#    for my $n ($grid->oneigh($o)) {
#      my ($nc,$nv) = @$n;
#      next if ($nv eq '#');
#      $nopen{$nc}++;
#    }
#  }
#  @open = keys(%nopen);
#}
#say scalar(@open); exit;

sub megagrid {
  my ($r,$c) = @_;
  $r+=65; $r %= 131;
  $c+=65; $c %= 131;
  return 0 if $grid->at($r,$c) eq '#';
  for my $n ($grid->oneigh($r,$c)) {
    return 1 if ($n->[2] ne '#');
  }
  return 0;
}

memoize('megagrid');

for my $r (1..131) {
  for my $c (1..131) {
    $sum++ if megagrid($r,$c);
  }
}

say "total = $sum";

my $sumb=0;
$sum=0;
my %list;

my $AA = (26501365-65)/131;
my $total = 14840;
my $in = 3751;
my $in_prime = 3651;

for my $A (0..5,$AA/2) {
  $A*=2;
  my $result = (($A+.5)*($A+.5)-.25) * $total - ($A * $in_prime) + ($A+1) * $in;
  my $x = $A * 131 + 65;
  say "A=$A x=$x result=$result";
}

for my $i (0..1375) {
  if ($i&1) {
    for my $j (0..$i) {
      my $r = $i-$j;
      my $c = $j;
      for my $coord ("$r,$c","-$r,$c","$r,-$c","-$r,-$c") {
        next if ($coord =~ /-0/o);
        my ($xr,$xc) = split(',', $coord);
        $sumb++;
        if (megagrid($xr,$xc)) {
          $sum++;
          #$list{$coord}++ and die;
        }
      }
    }
  }
  say "$i $sum $sumb" if (($i % 262) == 65);
}




#my @list = keys %list;

#$sgrid->print(@list);

out ($sum);

#out (scalar(@list));

# 3751 (65) = in (odd)

# 3651 (64) = in'
# 14840 = full grid

#65 3751 4356
#196 33235 38416
#327 93003 107584
#458 181455 209764
#589 300991 348100
#720 448411 518400
#851 627715 725904
#982 834103 964324
#1113 1073175 1240996
#1244 1338531 1547536
#1375 1637371 1893376

