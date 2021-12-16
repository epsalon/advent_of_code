#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

# Utility function to make sure 2d array has equal rows
# input arr,fill. no output
sub equalize {
  my $arr = shift;
  my $fill = shift;
  my $rows = @$arr;
  my $cols = max(map {$_ ? scalar(@$_): 0} @$arr);
  print "$rows $cols\n";
  for my $row (@$arr) {
    $row = [] unless $row;
    while (@$row < $cols) {
      push @$row, $fill;
    }
  }
}

# Find neighbors
# input neigh_arr, arr, row, col
# OR: neigh_arr, arr, "row,col"
# OR: neigh_arr, rows, cols, row, col
# OR: neigh_arr, rows, cols, "row,col"
# returns array of [row, col, value]
# OR: array of ["row,col", value]
# OR: array of "row,col"
sub neigh {
  my $neigh = shift;
  my ($rows,$cols);
  my $arr = shift;
  if (ref $arr) {
    $rows = @$arr;
    $cols = @{$arr->[0]};
  } else {
    $rows = $arr;
    $cols = shift;
    undef $arr;
  }
  my $row = shift;
  my $col = shift;
  my $comma;
  if ($row =~ /(\d+)(\D+)(\d+)/) {
    ($row, $comma, $col) = ($1, $2, $3);
  }
  my @out;
  for my $pair (@$neigh) {
    my ($rd, $cd) = @$pair;
    my ($nr, $nc) = ($row + $rd, $col + $cd);
    next if $nr < 0;
    next if $nc < 0;
    next if $nr >= $rows;
    next if $nc >= $cols;
    if (defined($comma)) {
      if ($arr) {
        push @out, ["$nr$comma$nc", $arr->[$nr][$nc]];
      } else {
        push @out, "$nr$comma$nc";
      }
    } else {
      push @out, [$nr, $nc, $arr ? ($arr->[$nr][$nc],) : ()];
    }
  }
  return @out;
}

# Orthogonal
sub oneigh {
  return neigh([[-1,0], [1, 0], [0, -1], [0, 1]], @_);
}

# All neighbors
sub aneigh {
  return neigh([
    [-1, -1], [-1, 0], [-1, 1],
    [ 0, -1],          [ 0, 1],
    [ 1, -1], [ 1, 0], [ 1, 1]], @_);
}

# Numeric sort because sort defaults to lex
# returns new array
sub nsort {
  my $in = \@_;
  if (@$in == 1) {
    $in = $in->[0];
  }
  return sort {$a <=> $b} @$in;
}

# Binary conversions
sub bin2dec {
  my $in = shift;
  return oct("0b$in");
}
sub dec2bin {
  my $in = shift;
  return sprintf ("%b", $in);
}
sub hex2bin {
  my $in = shift;
  return join('', map {sprintf("%04b", oct("0x$_"))} split('', $in));
}

# A* / BFS implementation
# Args: start, end, neighbor function, heuristic function
# neighbor function: node -> [[new_node, cost], ...]
#   cost assumed 1 if missing
# heuristic function: node -> lower bound on cost to end
sub astar {
  my ($start, $end, $neigh, $h) = @_;
  $h = sub {return 0;} unless $h;

  my $OPEN = new List::PriorityQueue;
  my %gscore = ($start, 0);
  my %OHASH = ($start, 1);
  my %path;
  $OPEN->insert($start, $h->($start));

  while (%OHASH) {
    my $cur = $OPEN->pop();
    delete $OHASH{$cur};
    if ($cur eq $end) {
      my $score = $gscore{$cur};
      return $score unless wantarray;
      my @path = ($cur);
      while ($cur = $path{$cur}) {
        unshift(@path, $cur)
      }
      return ($score, @path);
    }
    for my $n ($neigh->($cur)) {
      my ($np,$v) = @$n;
      if (!defined($v)) {
        $v = 1;
      }
      my $new_g = $gscore{$cur} + $v;
      if (!exists($gscore{$np}) || $new_g < $gscore{$np}) {
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

my $n=0;

sub new_node {
  return "n".$n++;
}

my $sum=0;

$_=<>;
chomp;

my @A = split('', hex2bin($_));

my @types = qw/+ * min max lit > < =/;

sub pp {
  my $bin = join('', @A[0..5]);
  my @v = splice(@A,0,3);
  my $v = bin2dec(join('', @v));
  $sum += $v;
  my @t = splice(@A,0,3);
  my $t = bin2dec(join('', @t));
  if ($t == 4) {
    my $c = 1;
    my @ov;
    while ($c) {
      $c = shift @A;
      push @ov, splice(@A,0,4);
    }
    $bin.=join('', @ov);
    my $res = bin2dec(join('', @ov));
    my $node = new_node;
    #say "  $node [label=\"$res\"];";
    return ($res, $res, $node, ["[$v] $res {$bin}"]);
  } else {
    my @vals;
    my @exps;
    my @nodes;
    my @trees;
    my $i = shift @A;
    my $proc = sub {
        my ($res, $exp, $node, $tree) = pp();
        $tree->[0] .= " (=$res)" if @$tree > 1;
        push @vals, $res;
        push @exps, $exp;
        push @nodes, $node;
        push @trees, $tree;
    };
    if ($i) {
      my $l = bin2dec(join('',splice(@A,0,11)));
      for my $j (1..$l) {
        $proc->();
      }
    } else {
      my $bl = join('',splice(@A,0,15));
      my $l = bin2dec($bl);
      my $cl = @A;
      while (@A > $cl - $l) {
        $proc->();
      }
    }
    my $node = new_node;
    #say "  $node [label=\"".$types[$t]."\"];";
    for my $on (@nodes) {
      #say "  $node -> $on;"
    }
    my $tree = ["[$v] ".$types[$t]. "  {$bin}", @trees];
    my $vv = join(', ', @exps);
    if ($t == 0) {
      return (sum(@vals), (@vals > 1 ? '('.join(' + ', @exps).')' : $vv), $node, $tree);
    } elsif ($t == 1) {
      return ((reduce {$a*$b} @vals), (@vals > 1 ? '('.join(' * ', @exps).')' : $vv), $node, $tree);
    } elsif ($t == 2) {
      return (min(@vals), (@vals > 1 ? "min($vv)" : $vv), $node, $tree);
    } elsif ($t == 3) {
      return (max(@vals), (@vals > 1 ? "max($vv)" : $vv), $node, $tree);
    } elsif ($t == 5) {
      return (($vals[0] > $vals[1]) || 0, "(".$exps[0]." > ".$exps[1].")", $node, $tree);
    } elsif ($t == 6) {
      return ($vals[0] < $vals[1]) || 0, "(".$exps[0]." < ".$exps[1].")", $node, $tree;
    } elsif ($t == 7) {
      return ($vals[0] == $vals[1]) || 0, "(".$exps[0]." == ".$exps[1].")", $node, $tree;
    }
  }
}

sub printree {
  my $tree = shift;
  my $prefix = shift // '';
  my $prefix1 = shift // $prefix;
  my $root = shift @$tree;
  say "$prefix1$root";
  for my $i (0..$#$tree) {
    my $subtree = $tree->[$i];
    if ($i == $#$tree) {
      printree($subtree, "$prefix   ", "$prefix └─");
    } else {
      printree($subtree, "$prefix │ ", "$prefix ├─");
    }
  }
}

#say "digraph {";
my @pp = pp();
#say "}";

$pp[3][0] .= " (=".$pp[0].")";

printree($pp[3]);

#out join(" ", @pp);
#out $sum;