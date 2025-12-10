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
use IPC::Open2;

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my %H;
my $sum=0;

#my $grid = Grid::Dense->read();

sub bitcount {
  my $v = shift;
  my $c=0;
  while ($v) {
    $v &= $v-1;
    $c++;
  }
  return $c;
}

while (<>) {
  chomp;
  last unless $_;
  m{\[(.+)\]\s+(.+?)\s+\{(.+)\}}o;
  my $t = $1;
  my $j = $3;
  my @b = reverse(map {/\((.+)\)/;sum(map {1 << $_} split(',',$1))} split(' ',$2));
  my @j = split(',', $j);
  my $lp = 'Min: '.join('+',map {"x$_"} (0..$#b)).";\n";
  for my $i (0..$#j) {
    my @o;
    for my $j (0..$#b) {
      if ((1<<$i) & $b[$j]) {
        push @o, "x$j";
      }
    }
    $lp.=join('+', @o)." = $j[$i];\n"
  }
  $lp .= 'int '.join(',',map {"x$_"} (0..$#b)).";\n";
  my $pid = open2(my $chld_out, my $chld_in, 'lp_solve', '-S1');
  print $chld_in $lp;
  close($chld_in);
  <$chld_out>;
  my $o=<$chld_out>;
  $o =~ m/\s+(\d+)\.0+$/ or die;
  $sum+=$1;
}

out ($sum);
