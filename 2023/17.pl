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
use AOC qw/out astar/;

my $sum=0;

$|=1;

my $g = Grid::Dense->read();

sub solve {
  my $g = shift;
  my $min_steps = shift;
  my $max_steps = shift;
  my $bias = shift // 1;
  my $max_row = $g->rows()-1;
  my $max_col = $g->rows()-1;

  return astar("0,0,0,0", sub {
    my $node = shift;
    return $node =~ /^$max_row,$max_col,/
  }, sub {
    my $node = shift;
    my ($r, $c, $rx, $cx) = split(',', $node);
    my @out;
    for my $dir ([-1,0],[1,0],[0,-1],[0,1]) {
      my ($dr,$dc) = @$dir;
      next if ($dr && $rx || $dc && $cx);
      my $cost;
      my ($nr,$nc) = ($r,$c);
      for my $d (1..$max_steps) {
        $nr += $dr; $nc += $dc;
        last unless $g->bounds($nr,$nc);
        $cost+=$g->at($nr,$nc);
        next if ($d < $min_steps);
        push @out,["$nr,$nc,".abs($dr).",".abs($dc), $cost];
      }
    }
    return @out;
  }, sub {
    my $node = shift;
    my ($r, $c) = split(',', $node);
    return ($max_row+$max_col-$r-$c)*$bias;
  });
}

my @out=solve($g,1,3);
$sum=shift(@out);
$g->print(@out);
out ($sum);

@out=solve($g,4,10);
$sum=shift(@out);
$g->print(@out);
out ($sum);
