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

# A* / BFS implementation
# Args: start, end, neighbor function, heuristic function
#  - start is either a node or a list of nodes to start at.
#  - end is either a node or a function that takes a single node
#    and returns true/false.
# - neighbor function: node -> ([new_node, cost], ...)
#   - cost assumed 1 if missing
# - heuristic function: node -> lower bound on cost to end (optional)
sub astar {
  my ($start, $end, $neigh, $h) = @_;
  # Generalize parameters
  $start = [$start] unless (ref($start) eq 'ARRAY');
  if (ref($end) ne 'CODE') {
    my $end_node = $end;
    $end = sub { return $_[0] eq $end_node; };
  }
  die "bad neigh func $neigh" unless (ref($neigh) eq 'CODE');
  $h = sub {return 0;} unless $h;

  # Initialize open list
  my $OPEN = new List::PriorityQueue;
  my %gscore;
  my %OHASH;
  for my $s (@$start) {
    $gscore{$s} = 0;
    $OHASH{$s} = 1;
    $OPEN->insert($s, $h->($s));
  }

  my %path;
  while (%OHASH) {
    my $cur = $OPEN->pop();
    delete $OHASH{$cur};
    # Check for end
    if ($end->($cur)) {
      say "reached end at $cur";
      my $score = $gscore{$cur};
      return $score unless wantarray;
      my @path = ($cur);
      while ($cur = $path{$cur}) {
        unshift(@path, $cur)
      }
      return ($score, @path);
    }
    # Expand neighbors
    for my $n ($neigh->($cur)) {
      my ($np,$v);
      if (ref($n) eq 'ARRAY') {
        ($np,$v) = @$n;
      } else {
        $np = $n;
      }
      if (!defined($v)) {
        $v = 1;
      }
      my $new_g = $gscore{$cur} + $v;
      if (!exists($gscore{$np}) || $new_g < $gscore{$np}) {
        # Found better path to $np
        $path{$np} = $cur if wantarray;
        $gscore{$np} = $new_g;
        my $fscore = $new_g + $h->($np);
        if (!$OHASH{$np}) {
          $OPEN->insert($np, $fscore);
          $OHASH{$np}++;
        } else {
          $OPEN->update($np, $fscore);
        }
      }
    }
  }
}

my $sum=0;

$|=1;

my $g = Grid::Dense->read();

sub solve {
  my $g = shift;
  my $min_steps = shift;
  my $max_steps = shift;
  my $max_row = $g->rows()-1;
  my $max_col = $g->rows()-1;

  return astar("0,0,0,0", sub {
    my $node = shift;
    my ($r, $c, $rx, $cx) = split(',', $node);
    return 0 if ($r != $max_row);
    return 0 if ($c != $max_col);
    return 0 if (abs($rx + $cx) < $min_steps);
    return 1;
  }, sub {
    my $node = shift;
    my ($r, $c, $rx, $cx) = split(',', $node);
    my @out;
    if ($rx + $cx == 0) {
      return (["1,0,1,0", $g->at(1,0)],["0,1,0,1", $g->at(0,1)])
    }
    my $cost = 0;
    while (abs($rx+$cx) < $min_steps) {
      my $dr=$rx && $rx/abs($rx);
      my $dc=$cx && $cx/abs($cx);
      $r+=$dr; $c+=$dc;
      $rx+=$dr; $cx+=$dc;
      return () unless $g->bounds($r,$c);
      $cost += $g->at($r,$c);
    }
    for my $n ([-1,0],[1,0],[0,-1],[0,1]) {
      my ($dr,$dc) = @$n;
      my $nr = $r+$dr;
      my $nc = $c+$dc;
      if ($rx && $dr) {
        next if abs($rx) == $max_steps;
        next if $rx*$dr < 0;
        $dr+=$rx;
      }
      if ($cx && $dc) {
        next if abs($cx) == $max_steps;
        next if $cx*$dc < 0;
        $dc+=$cx;
      }
      next unless $g->bounds($nr,$nc);
      my $v = $g->at($nr,$nc);
      push @out,["$nr,$nc,$dr,$dc", $v+$cost];
    }
    return @out;
  }, sub {
    my $node = shift;
    my ($r, $c) = split(',', $node);
    return $max_row+$max_col-$r-$c;
  });
}

my @out=solve($g,0,3);
$sum=shift(@out);
$g->print(map {m{^(\d+),(\d+),}; [$1,$2]} @out);
out ($sum);

@out=solve($g,4,10);
$sum=shift(@out);
$g->print(map {m{^(\d+),(\d+),}; [$1,$2]} @out);
out ($sum);
