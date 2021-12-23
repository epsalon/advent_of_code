#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs/;
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
sub bin2hex {
  my $in = shift;
  my $out;
  my @in = split('', $in);
  die "Bad bin value $in" if (@in%4);
  while (@in) {
    $out .= sprintf("%X", bin2dec(join('',splice(@in, 0, 4))));
  }
  return $out;
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
  return "NOT FOUND";
}

my @A;
my %H;
my $sum=0;

#my $roomsize = 2;

#my $start = '#00000000000#|BACDBCDA'; # example

#my $start = '#00000000000#|DCBADABC'; # real
#my $end =   '#00000000000#|AABBCCDD';

my $start = '#00000000000#|DDDCBCBADBAABACC'; # real
my $end =   '#00000000000#|AAAABBBBCCCCDDDD';

my $roomsize = 4;

my %COSTS = qw/A 1 B 10 C 100 D 1000/;
my %DESTS = qw/A 0 B 1 C 2 D 3/;

sub nf {
  my $state = shift;
  my @out;
  #say "$state";
  $state =~ m{\|(.+)}o or die;
  my @p = split('', $1);
  $state =~ m{^(.+)\|}o or die;
  my @hallway = split('', $1);
  my @can_move;
  for my $i (0..@p/$roomsize-1) {
    my @np = @p;
    for my $e (0..$roomsize-1) {
      if ($p[$roomsize*$i+$e]) {
        $np[$roomsize*$i+$e] = 0;
        push @can_move, [$p[$roomsize*$i+$e], $i, $e + 1, join('', @np)];
        last;
      }
    }
  }
  #print Dumper(\@can_move);
  for my $h (@can_move) {
    my ($id, $loc, $init_cost, $room_state) = @$h;
    $loc *= 2;
    $loc += 3;
    my $min = $loc;
    my $max = $loc;
    while (!$hallway[$min]) {
      $min--;
    }
    $min++;
    while (!$hallway[$max]) {
      $max++;
    }
    $max--;
    #say "id=$id loc=$loc init_cost=$init_cost room_state=$room_state min=$min max=$max";
    for my $pos ($min..$max) {
      next if $pos == 3;
      next if $pos == 5;
      next if $pos == 7;
      next if $pos == 9;
      my $steps = abs($pos-$loc) + $init_cost;
      my $cost = $steps * $COSTS{$id};
      my @nh = @hallway;
      $nh[$pos] = $id;
      my $new_state = join('', @nh).'|'.$room_state;
      push @out, [$new_state, $cost];
    }
  }
  for my $i (0..$#hallway) {
    next unless $hallway[$i] =~ /[ABCD]/;
    my $id = $hallway[$i];
    my $min = $i-1;
    my $max = $i+1;
    while (!$hallway[$min]) {
      $min--;
    }
    $min++;
    while (!$hallway[$max]) {
      $max++;
    }
    $max--;
    my $dest = $DESTS{$id};
    my $destpos = 2*$dest + 3;
    if ($destpos >= $min && $destpos <= $max) {
      my $extra_cost = 0;
      for my $e (0..$roomsize-1) {
        $e = $roomsize - 1 - $e;
        if ($p[$roomsize*$dest+$e] eq '0') {
          $extra_cost=$e + 1;
          last;
        } elsif ($p[$roomsize*$dest+$e] ne $id) {
          last;
        }
      }
      if ($extra_cost) {
        my $steps = abs($i-$destpos) + $extra_cost;
        my $cost = $steps * $COSTS{$id};
        my @nh = @hallway;
        $nh[$i] = 0;
        my @np = @p;
        #say "np = ",join('', @np);
        $np[$roomsize*$dest - 1 + $extra_cost] = $id;
        my $new_state = join('', @nh). '|'. join('', @np);
        push @out, [$new_state, $cost];
      }
    }
  }
  #say "$state ".join(';', map {join(',', @$_)} @out);
  return @out;
}

#nf('#000B0000000#|BACD0CDA');

out(astar($start,$end,\&nf));