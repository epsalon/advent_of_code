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
use POSIX;

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

while (<>) {
  chomp;
  last unless $_;
  push @A, [split('')];
}

my $path = <>;
chomp $path;

sub left {
  my $r = shift;
  die "$r" unless $A[$r];
  my @arr=@{$A[$r]};
  for my $i (0..$#arr) {
    return $i if $arr[$i] ne ' ';
  }
}

sub right {
  my $r = shift;
  my @arr=@{$A[$r]};
  for my $i (0..$#arr) {
    my $c = $#arr-$i;
    return $c if $arr[$c] ne ' ';
  }
}

sub top {
  my $c = shift;
  for my $i (0..$#A) {
    return $i if ($A[$i][$c] ne ' ');
  }
}

sub bot {
  my $c = shift;
  for my $i (0..$#A) {
    my $r = $#A-$i;
    return $r if (($A[$r][$c] || ' ') ne ' ');
  }
}

memoize('left');
memoize('right');
memoize('bot');
memoize('top');

sub getsize {
  my $n;
  for my $r (@A) {
    for my $c (@$r) {
      $n++ if ($c ne ' ');
    }
  }
  return sqrt($n/6);
}

my $SIZE = getsize();

sub getnet {
  my @net;
  for my $r (0..(@A/$SIZE)-1) {
    my @nrow;
    my $ra = $A[$r*$SIZE];
    for my $c (0..(@$ra/$SIZE)-1) {
      push @nrow, ($ra->[$c*$SIZE] eq ' ' ? 0 : 1);
    }
    push @net, \@nrow;
  }
  return @net;
}

my @NET = getnet();

sub nv {
  my $p = shift;
  my ($r,$c) = (Im($p),Re($p));
  return 0 if ($r < 0 || $r > $#NET);
  return 0 if ($c < 0);
  return $NET[$r][$c] || 0;
}

sub fixarr {
  my ($p,$f) = @_;
  $p+=$f;
  return ($p, $f) if (nv($p));
  $p-=$f; # undo
  # L1R1L
  $f*=-i;
  ($p, $f) = fixarr($p,$f);
  $f*=i;
  ($p, $f) = fixarr($p,$f);
  $f*=-i;
  return ($p,$f);
}

memoize('fixarr');

sub fa {
  my ($r,$c,$f) = @_;
  my ($p,$nf) = fixarr($r*i+$c,$f);
  return (Im($p),Re($p),$f/$nf);
}

#for my $r (0..3) {
#  for my $c (0..2) {
#    my $p = $r*i+$c;
#    next unless nv($p);
#    for my $f (-1,1,-i,i) {
#      my ($np,$nf) = fixarr($p,$f);
#      my $df = $f/$nf;
#      say "fixarr($p,$f) = ($np,$nf) [df=$df]";
#    }
#  }
#}
#exit;

sub fix {

  # 0,1,-1 (row) => 2,0,-1  [1] (row=50-r) -1
  # 0,1,-i (col) => 3,0,-i  [1] (row=c)     i
  # 0,2,-i (col) => 3,0,1  [-i] (col=c)     1
  # 1,1,-1 (row) => 2,0,i   [i] (col=r)     i
  # 1,1,+1 (row) => 0,2,i  [-i] (col=r)     i


  # **T**           **L**
  # L   R - +50 ->  B   T X =i
  # **B**           **R**
  #  p       =>       p/X-50 F/X


  my %FIX = (qw/01-1 2,0,-1 01-i 3,0,-i 02-i 3,0,1 021 2,1,-1 02i 1,1,-i 11-1 2,0,i 111 0,2,i 20-i 1,1,-i 20-1 0,1,-1 211 0,2,-1 21i 3,0,-i 30-1 0,1,i 301 2,1,i 30i 0,2,1/);
  my ($r,$c,$of) = @_;  
  my $opos = i * $r + $c;
  $opos += $of;
  my $Mr = POSIX::floor($r / $SIZE);
  my $Mc = POSIX::floor($c / $SIZE);
  my $pos = i * ($r % $SIZE) + ($c % $SIZE);
  $pos += $of;
  my ($nMc, $nMr) = (POSIX::floor(Re($opos)/$SIZE), POSIX::floor(Im($opos)/$SIZE));
  #say "Checking opos=$opos of=$of Mr=$Mr Mc=$Mc nMr=$nMr nMc=$nMc r=$r c=$c pos=$pos";
  return ($opos,$of) if ($nMc == $Mc && $nMr == $Mr);
  #say "Found boundary opos=$opos pos=$pos f=$of";
  my $fix = $FIX{"$Mr$Mc$of"};
  #return ($opos,$of) unless $fix;
  #my ($Nr, $Nc, $Nf) = split(',', $fix);
  my ($Nr, $Nc, $Nf) = fa($Mr,$Mc,$of);
  #say "Need to fix: r=$r c=$c of=$of pos=$pos Nr=$Nr Nc=$Nc Nf=$Nf";
  $Nf = eval($Nf);
  my $f=$of;
  $f = $f / $Nf;
  $pos -= $SIZE*$of;
  #say "after moving $SIZE towards $of pos = $pos";
  $pos -= ($SIZE-1)/2 + ($SIZE-1)/2*i;
  $pos /= $Nf;
  $pos += ($SIZE-1)/2 + ($SIZE-1)/2*i;
  #say "after translating by diving by $Nf pos = $pos";
  $pos += $Nr*i*$SIZE + $Nc*$SIZE;
  #say "final position is $pos facing $f";
  return ($pos,$f);
}

my $p = left(0);
my $f = 1;

memoize('fix');

sub tryfix {
  my ($r,$c,$f) = @_;
  #say "============ TRYFIX($r,$c,$f) =============";
  my ($p,$f1) = fix(@_);
  $f1*=-1;
  my ($c1,$r1) = (Re($p), Im($p));
  my ($p2,$f2) = fix($r1,$c1,$f1);
  $f2*=-1;
  my ($c2,$r2) = (Re($p2), Im($p2));
  die "$r $c $f" unless ($r == $r2 && $c == $c2 && $f == $f2);
}

#for my $r (0..$#A) {
#  my $c = left($r);
#  my $f = -1;
#  tryfix($r,$c,$f);
#  $c = right($r);
#  $f = 1;
#  tryfix($r,$c,$f);
#}

#for my $c (0..$#{$A[0]}) {
#  my $r = top($c);
#  my $f = -i;
#  tryfix($r,$c,$f);
#  $r = bot($c);
#  $f = i;
#  tryfix($r,$c,$f);
#}

while ($path) {
  #say "p = $p f = $f path = $path";
  if ($path =~ /^(\d+)/) {
    my $n=$1;
    $path = $';
    for my $i (1..$n) {
      my ($pp,$pf)=($p,$f);
      my ($c,$r) = (Re($p), Im($p));
      ($p,$f) = fix($r,$c,$f);
      ($c,$r) = (Re($p), Im($p));
      #say "MOVEMENT: p=$p r=$r c=$c";
      #exit;
      die "p=$p r=$r c=$c" unless $A[$r][$c];
      die "p=$p r=$r c=$c" if ($A[$r][$c] eq ' ' || $r <0 || $c < 0);
      if ($A[$r][$c] eq '#') {
        #say "Found wall at $p";
        $p = $pp; $f = $pf;
        last;
      }
    }
  } elsif ($path =~ /(L|R)/) {
    my $d=$1;
    $path=$';
    $f *= i;
    if ($d eq 'L') {
      $f *= -1;
    }
  }
}

my %FLOOKUP = (-i,3,i,1,-1,2,1,0);
my ($r,$c) = (Im($p)+1, Re($p)+1);

out($r*1000+$c*4+$FLOOKUP{$f});