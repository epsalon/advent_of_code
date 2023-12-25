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

my $i=1;
sub id {
  if (!$H{$_[0]}) {
    $H{$_[0]} = $i++;
  }
  return $H{$_[0]};
}
while (<>) {
  chomp;
  my ($a,$b) = split(': ');
  for my $x (split(' ',$b)) {
    my ($x1,$x2) = ($a lt $x ? ($a,$x) : ($x,$a));
    #say "$x1 -- $x2";
    #say "graph.edge.append(Edge(".id($x1).",".id($x2)."))";
    $H{$x1}{$x2}++;
    $H{$x2}{$x1}++;
  }
  $b =~ s/ /","/go;
  #print "[\"$a\",\"$b\"],";
}

delete $H{lxb}{vcq};
delete $H{rnx}{ddj};
delete $H{mmr}{znk};
delete $H{vcq}{lxb};
delete $H{ddj}{rnx};
delete $H{znk}{mmr};

my @open = 'mmr';
my %closed;
while (@open) {
  my $x = shift @open;
  say "$x";
  $closed{$x}++;
  for my $y (keys %{$H{$x}}) {
    next if $closed{$y};
    push @open,$y;
  }
}

out(scalar(%closed));

out(scalar(%closed)* (%H - %closed));

#say $i;
#out(\%H);

#out ($sum);
