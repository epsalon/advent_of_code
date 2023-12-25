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
use Memoize qw(memoize flush_cache);
use Storable qw(dclone);
use bigrat;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

my %H;
my $sum=0;

while (<>) {
  chomp;
  m{(\w+): ((\d+)|(\w+) (.) (\w+))};
  if (defined($3)) {
    $H{$1}=$3;
  } else {
    $H{$1}=[$5,$4,$6];
  }
}

sub build_tree {
  my $node = shift;
  my $val = $H{$node};
  #say "node = $node val = $val";
  return $val unless ref($val);
  my $op = $val->[0];
  my $t1 = build_tree($val->[1]);
  my $t2 = build_tree($val->[2]);
  #say "t1 = $t1 t2 = $t2 op = $op";
  if (ref($t1) ne 'ARRAY' && ref($t2) ne 'ARRAY' && $t1 ne 'H' && $t2 ne 'H') {
    #say "  doing eval";
    return eval("$t1 $op $t2");
  }
  return [
    $val->[0], build_tree($val->[1]),
    build_tree($val->[2])];
}

memoize('build_tree');

say(build_tree('root'));

flush_cache('build_tree');

sub human {
  my $node = shift;
  return ref($node) eq 'ARRAY' || $node eq 'H'
}

$H{'humn'} = 'H';
$H{'root'}[0] = '=';
my $TREE = build_tree('root');
while ($TREE->[1] ne 'H') {  
  #out($TREE);
  # Ensure human tree on left
  if (human($TREE->[2]))  {
    ($TREE->[1], $TREE->[2]) = ($TREE->[2], $TREE->[1]);
    next;
  }
  # Look into human tree
  my $ltree = $TREE->[1];
  my $lop = $ltree->[0];
  # If right of human tree is human, flip it
  if (human($ltree->[2])) {
    ($ltree->[1],$ltree->[2]) = ($ltree->[2],$ltree->[1]);
    my $rtree = $TREE->[2];
    if ($lop eq '/') {
      $TREE->[2] = 1/$rtree;
    } elsif ($lop eq '-') {
      $TREE->[2] = -$rtree;
    }
  }
  # Now the human tree is (f(h) op [number])
  my $revop = $lop;
  $revop =~ tr|\*\/\-\+|\/\*\+\-|;
  my $ltree2 = $ltree->[2];
  $TREE->[1] = $ltree->[1];
  my $rtree = $TREE->[2];
  $TREE->[2] = eval("$rtree $revop $ltree2");
}

say($TREE->[2]);
