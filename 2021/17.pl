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
use POSIX qw/ceil/;
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
}

my @A;
my %H;
my $sum=0;

$_=<>;
chomp;
my ($x1,$x2,$y0,$y1) = m{x=([-\d]+)\.\.([-\d]+), y=([-\d]+)\.\.([-\d]+)}o or die;

#
# Y_n = n * vy_0 - (n-1)*n/2 
# X_n = q * vx_0 - (q-1)*q/2 [ q = min(n,vx_0)]
#
# - 0.5q^2 + 1.5 * vx_0 * q - X_n[ q = min(n,vx_0)]
# 
# v_t = v_0 - t

sub y_to_n  {
  my ($vy, $y) = @_;
  my $s1 = 0.5 * (-sqrt(-8 * $y + 4*$vy*$vy + 4 * $vy + 1) + 2* $vy + 1);
  my $s2 = 0.5 * (sqrt(-8 * $y + 4*$vy*$vy + 4 * $vy + 1) + 2* $vy + 1);
  return max($s1,$s2)
}

sub x_to_n {
  my ($vx, $x) = @_;
  my $s1 = 0.5 * (-sqrt(-8 * $x + 4*$vx*$vx + 4 * $vx + 1) + 2* $vx + 1);
  my $s2 = 0.5 * (sqrt(-8 * $x + 4*$vx*$vx + 4 * $vx + 1) + 2* $vx + 1);
  my @s;
  push @s, $s1 if ($s1 <= $vx && $s1 >= 0);
  push @s, $s2 if ($s2 <= $vx && $s2 >= 0);
  return max(@s);
}

sub y_of_t {
  my ($vy, $t) = @_;
  return $vy*$t - ($t-1)*$t/2;
}

my $ymax = max(abs($y1), abs($y0));
my $tmax = 3*$ymax;

my %XMAP;

for my $vx (0..max($x1,$x2)) {
  my @ns;
  my $n1 = x_to_n($vx, $x1);
  my $n2 = x_to_n($vx, $x2);
  push @ns, $n1 if $n1;
  push @ns, $n2 if $n2;
  say "vx=$vx ns=",join(',', @ns);
  next unless (@ns);
  for my $ns (ceil($n1)..($n2 || $tmax)) {
    push @{$XMAP{$ns}}, $vx;
  }
}

my $ok=1;
my $mvy;
my $nn;
my %sols;
for my $vy (-$ymax..$ymax) {
  my $n1 = y_to_n($vy, $y0);
  my $n2 = y_to_n($vy, $y1);
  say "vy=$vy n1=$n1 n2=$n2";
  say "  y(".int($n1).")=".y_of_t($vy,int($n1));
  say "  y(".int($n2).")=".y_of_t($vy,int($n2));
  $nn=min(int($n1),int($n2));
  unless (int($n1) == int($n2) && ($n1 != int($n1)) && ($n2 != int($n2))) {
    $mvy = $vy;
    my %xx;
    for my $ys (ceil($n2)..int($n1)) {
      for my $vx (@{$XMAP{$ys}}) {
        $xx{$vx}++;
        $sols{"$vx,$vy"}++;
      }
    }
  }
}


my $vy=$mvy;

out $vy;

my $yy1 = $vy*$vy - ($vy-1)*$vy/2;

for my $y (-$ymax..$ymax) {
  for my $x (0..202) {
    print $sols{"$x,$y"}?"#":" ";
  }
  print "\n";
}

out $yy1;
say STDERR join("\n", sort(keys %sols));
out scalar(%sols);
