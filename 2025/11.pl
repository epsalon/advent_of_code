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

my @A;
my %H;
my $sum=0;

#my $grid = Grid::Dense->read();

open(G,">11.graph") or die;

print G "digraph aoc {";

for my $s ('svr', 'you', 'fft', 'dac', 'out') {
  print G "$s [style=filled];\n";
}

while (<>) {
  chomp;
  last unless $_;
  my @x = split(' ');
  my $s=shift @x;
  chop $s;
  for my $x (@x) {
    push @{$H{$x}}, $s;
    print G "  $s -> $x;\n";
  }
}

print G "}";

close(G);

sub pc {
  my $s = shift;
  my $d = shift;
  if ($d eq $s) {
    return 1;
  }
  my $v=0;
  for my $p (@{$H{$d}}) {
    $v+=pc($s, $p);
  }
  return $v;
}

memoize('pc');

dbg(\%H);

out (pc('you', 'out'));

for my $pair ('svr,fft', 'fft,dac', 'dac,out', 'svr,dac', 'dac,fft', 'fft,out') {
  say "$pair = ". pc(split(',', $pair));
}

out(pc('svr','fft') * pc('fft', 'dac') * pc('dac', 'out') +
pc('svr','dac') * pc('dac', 'fft') * pc('fft', 'out'));
