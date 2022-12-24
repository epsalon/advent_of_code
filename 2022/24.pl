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
use Memoize;
use Storable qw(dclone);

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

sub smart_split {
  my $str = shift || $_;
  return ($str =~ m{[a-zA-Z]+|\d+}go);
}

sub hashify {
  my @arr = ref $_[0] ? @{$_[0]} : @_;
  return map {$_ => 1} @arr;
}

my @A;
my %H;
my $sum=0;

<>;

my $rl=1;
my $cl;

my %DIRS = ('<', [0,-1], '>', [0,1], '^', [-1,0], 'v', [1,0]);

while (<>) {
  chomp;
  last if /##/;
  my @X = split('');
  $cl = $#X-1;
  for my $c (1..$#X-1) {
    if (my $d = $DIRS{$X[$c]}) {
      push @A,[$rl,$c-1,@$d];
    }
  }
  $rl++;
}

my $start = "0,0;".join(';', map {join(',', @$_)} @A);

sub end {
  my $node = shift;
  my ($xr) = split(',', $node);
  return $xr == $rl;
}

sub movevort {
  my @vortex = @_;
#  say "movevort";
#  say join(';', @vortex);
  @vortex = map {[split(',')]} @vortex;
  for my $v (@vortex) {
    my ($r,$c,$rd,$cd) = @$v;
    $r+=$rd; $c+=$cd;
    $r=1 if $r == $rl;
    $r=$rl-1 if $r == 0;
    $c=0 if $c == $cl;
    $c=$cl-1 if $c < 0;
    $v = [$r,$c,$rd,$cd];
  }
  return @vortex;
}

memoize('movevort');

sub nneigh {
  my $node = shift;
  my ($pos,@vortex) = split(';', $node);
  my ($r,$c) = split(',', $pos);
  #out (\@vortex);
  @vortex = movevort(@vortex);
  #out (\@vortex);
  my %V;
  for my $v (@vortex) {
    my ($vr,$vc) = @$v;
    $V{$vr,$vc}++;
  }
  my @options;
  push @options, "$r,$c" unless $V{$r,$c};
  for my $d (values %DIRS) {
    my ($nr,$nc) = ($r,$c);
    my ($dr,$dc) = @$d;
    $nr+=$dr;
    $nc+=$dc;
    next if $V{$nr,$nc};
    next if $nc < 0;
    next if $nc >= $cl;
    next if ($nr < 0 || $nr > $rl);
    next if ($nr == 0 && $nc != 0);
    next if ($nr == $rl && $nc != $cl-1);
    push @options, "$nr,$nc";
  }
  unless (@options) {
    return ();
  }
  my $vstr = ";".join(';', map {join(',', @$_)} @vortex);
  my @out;
  for my $o (@options) {
    push @out, $o.$vstr;
  }
#  out(\@out);
  return @out;
}

sub heuristic {
  my $node = shift;
  my ($pos) = split(';', $node); 
  my ($r,$c) = split(',', $pos);
  return $cl-$c-1 + $rl-$r;
}

out(astar($start,\&end,\&nneigh,\&heuristic));
