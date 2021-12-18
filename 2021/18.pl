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
use POSIX qw/ceil floor/;

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

while (<>) {
  chomp;
  last unless $_;
  push @A, $_;
}

sub ssum {
  my ($a, $b) = @_;
  my $s = "[$a,$b]";
  my $go=1;
  GO: while ($go) {
    my @s = split('', $s);
    $go=0;
    my $p=0;
    my $ld=-2;
    for my $i (0..$#s) {
      $p++ if $s[$i] eq '[';
      $p-- if $s[$i] eq ']';
      $ld = $i if ($s[$i] =~ /\d/ && ($ld != $i-1));
      if ($p == 5) {
        $i--;
        my $rest = join('',splice(@s,$i));       
        my ($d1, $d2) = $rest =~ m{\[(\d+),(\d+)\]}o or die;
        my ($before,$after) = ($`,$');
        push @s, split('', $before), 0;
        $after =~ s{(\d+)}{$1 + $d2}eo;
        push @s, split('', $after);

        if ($ld >= 0) {
          my $prevdigit = join('',splice(@s,$ld));
          #say "pd = $prevdigit ld=$ld";
          $prevdigit =~ s{(\d+)}{$1 + $d1}oe;
          #say "pd = $prevdigit ld=$ld";
          push @s, $prevdigit;
        }

        $s = join('',@s);
        $go=1;
        #say "## $s";
        next GO;
      }
      $s = join('', @s);
    }
    my $ps=$s;
    $s =~ s{(\d\d+)}{$1 > 9  ? "[".floor($1/2).",".ceil($1/2)."]" : $1}e;
    #say "!! $s";
    $go=1 if ($ps ne $s);
  }
  return $s;
}

sub mag {
  my $s = shift;
  while ($s =~ s{\[(\d+),(\d+)\]}{$1*3 + 2*$2}eg) {};
  return $s;
}

my @B = @A;

while (@A > 1) {
  my $n1 = shift @A;
  my $n2 = shift @A;
  unshift @A, ssum($n1,$n2);
}

my $s = $A[0];
while ($s =~ s{\[(\d+),(\d+)\]}{$1*3 + 2*$2}eg) {};
out ($s);

my @o;
for my $i (0..$#B-1) {
  for my $j ($i+1..$#B) {
    my $s = mag(ssum($B[$i], $B[$j]));
    push @o, $s;
  }
}
out max(@o);