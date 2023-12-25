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
use Bit::Vector;

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

sub hashify {
  my @arr = @_;
  my %H;
  for my $i (0..$#arr) {
    $H{$arr[$i]}=$i;
  }
  return %H;
}

my @X;
my @Y;
my @Z;

while (<>) {
  chomp;
  push @A, [m{(on|off) x=(-?\d+)..(-?\d+),y=(-?\d+)..(-?\d+),z=(-?\d+)..(-?\d+)}];
}

for my $a (@A) {
  my ($s,$x1,$x2,$y1,$y2,$z1,$z2) = @$a;
  push @X, $x1;
  push @X, $x2+1;
  push @Y, $y1;
  push @Y, $y2+1;
  push @Z, $z1;
  push @Z, $z2+1;
}

@X = uniq(nsort(@X));
@Y = uniq(nsort(@Y));
@Z = uniq(nsort(@Z));

my (%X, %Y, %Z);
%X = hashify(@X);
%Y = hashify(@Y);
%Z = hashify(@Z);

sub idx {
  my ($x,$y,$z) = @_;
  return $x + $y*@X + $z*@X*@Y;
}

my $vector = Bit::Vector->new(@X*@Y*@Z);

for my $a (@A) {
  my ($s,$x1,$x2,$y1,$y2,$z1,$z2) = @$a;
  my $ix1 = $X{$x1};
  my $ix2 = $X{$x2+1};
  my $iy1 = $Y{$y1};
  my $iy2 = $Y{$y2+1};
  my $iz1 = $Z{$z1};
  my $iz2 = $Z{$z2+1};
  $s = ($s eq 'on');
  say "ix1=$ix1 ix2=$ix2 iy1=$iy1 iy2=$iy2 iz1=$iz1 iz2=$iz2";
  for my $ix ($ix1..$ix2-1) {
    for my $iy ($iy1..$iy2-1) {
      for my $iz ($iz1..$iz2-1) {
        if ($s) {
          $vector->Bit_On(idx($ix,$iy,$iz));
        } else {
          $vector->Bit_Off(idx($ix,$iy,$iz));
        }
      }
    }
  }
}

for my $ix (0..$#X-1) {
  say "ix=$ix of ".($#X-1);
  my $dx = $X[$ix+1] - $X[$ix];
  for my $iy (0..$#Y-1) {
    my $dy = $Y[$iy+1] - $Y[$iy];
    for my $iz (0..$#Z-1) {
      my $dz = $Z[$iz+1] - $Z[$iz];
      if ($vector->bit_test(idx($ix,$iy,$iz))) {
        $sum += $dx*$dy*$dz;
      }
    }
  }
}

out($sum);
