#!/usr/bin/perl -w
use strict;
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

my $sum=0;

$_=<>;
chomp;
my @A = map {sprintf("%04b", oct("0x$_"))} split('');
$_ = join('', @A);


@A = split('');

sub pp {
  my @v = splice(@A,0,3);
  my $v = bin2dec(join('', @v));
  $sum += $v;
  my @t = splice(@A,0,3);
  my $t = bin2dec(join('', @t));
  if ($t == 4) {
    my $n = 1;
    my $c=1;
    my @ov;
    while ($c) {
      $c = shift @A;
      push @ov, splice(@A,0,4);
      $n+=4;
    }
    return bin2dec(join('', @ov))
  } else {
    my @vals;
    my $i = shift @A;
    if ($i) {
      my $l = bin2dec(join('',splice(@A,0,11)));
      for my $j (1..$l) {
        push @vals, pp();
      }
    } else {
      my $bl = join('',splice(@A,0,15));
      my $l = bin2dec($bl);
      my $cl = @A;
      while (@A > $cl - $l) {
        push @vals, pp();
      }
    }
    if ($t == 0) {
      return sum(@vals);
    } elsif ($t == 1) {
      return reduce {$a*$b} @vals;
    } elsif ($t == 2) {
      return min(@vals);
    } elsif ($t == 3) {
      return max(@vals);
    } elsif ($t == 5) {
      return $vals[0] > $vals[1];
    } elsif ($t == 6) {
      return $vals[0] < $vals[1];
    } elsif ($t == 7) {
      return $vals[0] == $vals[1];
    }
  }
}

out (pp());
out $sum;