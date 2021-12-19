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
use POSIX qw/floor ceil/;

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
my @DONE;

BIG: while (<>) {
  chomp;
  m{scanner (\d+)};
  my $sn=$1;
  $_ = <>; chomp;
  while ($_) {
    push @{$A[$sn]}, [split(',')];
    $_ = <>;
    last BIG unless $_;
    chomp;
  }
}

my $b0 = shift @A;
my %h0;
for my $b (@$b0) {
  $H{join(',', @$b)} = 1;
  $h0{join(',', @$b)} = 1;
}
push @DONE, \%h0;

my @ROTLIST = (
[qw(-z -y -x)],
[qw(-z -x y)],
[qw(-z x -y)],
[qw(-z y x)],
[qw(-y -z x)],
[qw(-y -x -z)],
[qw(-y x z)],
[qw(-y z -x)],
[qw(-x -z -y)],
[qw(-x -y z)],
[qw(-x y -z)],
[qw(-x z y)],
[qw(x -z y)],
[qw(x -y -z)],
[qw(x y z)],
[qw(x z -y)],
[qw(y -z -x)],
[qw(y -x z)],
[qw(y x -z)],
[qw(y z x)],
[qw(z -y x)],
[qw(z -x -y)],
[qw(z x y)],
[qw(z y -x)]
);

sub rot {
  my $b = shift;
  my $r = shift;
  my ($x,$y,$z) = @$b;
  my $out = [map {my $q = $_; $q=~s{x}{$x}go;$q=~s{y}{$y}go;$q=~s{z}{$z}go;$q=~s{--}{}go; $q} @$r];
  return $out;
}

sub allrots {
  my $s = shift;
  my @out;
  for my $rot (@ROTLIST) {
    push @out, [map {rot($_, $rot)} @$s];
  }
  return @out;
}

sub delta {
  my ($p1, $p2) = @_;
  return [$p1->[0] - $p2->[0], $p1->[1] - $p2->[1], $p1->[2] - $p2->[2]]
}

sub add {
  my ($p1, $p2) = @_;
  return [$p1->[0] + $p2->[0], $p1->[1] + $p2->[1], $p1->[2] + $p2->[2]]
}

memoize('allrots');

my @SCANNERS=([0,0,0]);

sub in_bounds {
  my $p = shift;
  SC: for my $s (@SCANNERS) {
    for my $d (delta($p,$s)) {
      next SC if ($d < -500 || $d > 500);
    }
    return 1;
  }
  return 0;
}

SIGNALS: while (@A) {
  say "BIG LOOP";
  my $b1 = \%H;
  #for my $b1 (reverse(@DONE)) {
  #  say "DONE loop";
    for my $ib2 (0..$#A) {
      say "ib2=$ib2";
      for my $rb2 (allrots($A[$ib2])) {
        for my $refstr (keys(%$b1)) {
          my @ref = split(',',$refstr);
          my $ref = \@ref;
          # ref=  reference beacon in canoncial coordinates
          ALIGNMENT: for my $p (@$rb2) {
            # p = seen beacon in scanner coords that we try to align with ref
            my $delta = delta($ref, $p);
            # delta = ref - p, which is -(location of ref in scanner coords)
            my $matches = 0;
            for my $p2 (@$rb2) {
              # p2 new beacon in scanner coords
              my $np = add($p2, $delta);
              if ($b1->{join(',', @$np)}) {
                $matches++;
              } elsif (in_bounds($np)) {
                next ALIGNMENT;
              }
            }
            if ($matches >= 12) {
              say "FOUND IT! ib2 = $ib2";
              push @SCANNERS, $delta;
              my %h1;
              for my $b (@$rb2) {
                $b = add($b, $delta);
                $H{join(',', @$b)} = 1;
                $h1{join(',', @$b)} = 1;
              }
              push @DONE, \%h1;
              splice(@A,$ib2,1);
              next SIGNALS;
            }
          }
        }
      }
    #}
  }
  die;
}

say join("\n", keys %H);

say "------";

say join("\n", map {join(",", @$_)} @SCANNERS);

out (scalar(keys %H));

my $maxd=0;
for my $b1 (@SCANNERS) {
  my ($x,$y,$z) = @$b1;
  for my $b2 (@SCANNERS) {
    my ($x2,$y2,$z2) = @$b2;
    my $d = abs($x2-$x) + abs($y2-$y) + abs($z2-$z);
    $maxd=$d if ($d > $maxd);
  }
}

out($maxd);