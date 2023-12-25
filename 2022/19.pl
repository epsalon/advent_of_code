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
  my @bestg = ((0) x 33);
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
      my ($t, $st, $rb) = split(';', $n);
      my @st = split(',', $st);
      my @rb = split(',', $rb);
      my $ng=$st[3] + ($rb[3]*(32-$t));
      #say "n=$n ng=$ng t=$t" if $ng > 0;
      if ($ng > $bestg[$t]) {
        $bestg[$t] = $ng;
        say "bestg[$t]=$ng";
      } elsif ($ng + (33-$t)*(32-$t)/2 < $bestg[$t]) {
        next;
      }
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
  return ($str =~ m{\d+}go);
}

sub hashify {
  my @arr = ref $_[0] ? @{$_[0]} : @_;
  return map {$_ => 1} @arr;
}

my @A;
my %H;
my $sum=0;
my $geodes=0;

my $tt=0;

sub nnn {
  my $BP = shift;
  my $maxs = shift;
  my $node = shift;
  my ($t, $st, $rb) = split(';', $node);
  my @st = split(',', $st);
  my @rb = split(',', $rb);
  #say "=========== $node ============";
  $t++;
  if ($t > 32) {
    my $g = $st[3] || 0;
    $geodes = $g if $geodes < $g;
    return ();
  }
  if ($t > $tt) {
    $tt=$t;
    say "time $tt";
  }
  my @out;
  my @pst=@st;
  my @qst=@st;
  for my $i (0..$#rb) {
    $pst[$i] += $rb[$i];
    $qst[$i] += $rb[$i];
    if ($i < 3) {
      my $max = ($maxs->[$i] - $rb[$i]) * (33-$t) + $rb[$i];
      if ($pst[$i] > $max) {
        #say "i=$i st[i] = ".$st[$i]." pst[i] = ".$pst[$i]." max = $max maxs = ".$maxs->[$i]." rb = ".$rb[$i] if $maxs->[$i] > $rb[$i];
        $pst[$i] = $max;
      }
    }
  }
  BPLOOP: for my $bld (0..$#$BP) {
    if ($bld <= 2) {
      my $max = ($maxs->[$bld] - $rb[$bld]) * (32-$t) + $rb[$bld];
      next if ($pst[$bld] >= $max);
    }
    my @nst = @pst;
    my @nrb = @rb;
    my $bent = $BP->[$bld];
    #out(\@nst);
    for my $i (0..$#$bent) {
      next BPLOOP if ($st[$i] < $bent->[$i]);
      $nst[$i] = $qst[$i] - $bent->[$i];
      $nst[$i] = $pst[$i] if ($nst[$i] > $pst[$i]);
      #say "nst[$i] -= ".$bent->[$i];
    }
    $nrb[$bld]++;
    $st = join(',', @nst);
    $rb = join(',', @nrb);
    push @out, "$t;$st;$rb";
    if ($bld >= 3) {
      return @out;
    }
  }
  $st = join(',', @pst);
  $rb = join(',', @rb);
  push @out, "$t;$st;$rb";
  #out(\@out);
  return @out;
}


sub mk_n {
  my $BP = shift;
  my @maxs=(0,0,0);
  for my $g (@$BP) {
    for my $i (0..$#$g) {
      $maxs[$i] = $g->[$i] if $g->[$i] > $maxs[$i];
    }
  }
  out(\@maxs);
  return sub {nnn($BP,\@maxs,@_)};
}

my @OUT;

$sum=1;
while (<>) {
  chomp;
  last unless $_;
  push @A, [split('')];
  my @p = smart_split();
  my ($a,$b,$c,$d,$e,$f,$g) = @p;
  print "a=$a;b=$b;c=$c;d=$d;e=$e;f=$f;g=$g\n";
  my @BP=([$b],[$c],[$d,$e],[$f,0,$g]);
  out (\@BP);
  $geodes = 0; $tt=0;
  astar("0;0,0,0,0;1,0,0,0", "", mk_n(\@BP));
  say "geodes = $geodes";
  push @OUT, $geodes;
  $sum*=$geodes;  
  last if $a==3;
}

out(\@OUT);
out ($sum);
