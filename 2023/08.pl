#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use Math::ModInt qw(mod);
use Math::ModInt::ChineseRemainder qw(cr_combine);
use Math::Prime::Util 'factor_exp';

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
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

# Print and array highlighting some cells
# Args:
#   - array ref, row, col, row, col, ...
#   - array ref, "row,col", "row,col", ...
#   - array ref, array of [row, col, row, col, ...]
#   - array ref, array of ["row,col", "row,col", ...]
#   - array ref, array of [[row, col, val?], ...]
#   - array ref, array of [["row,col", val?], ...]
sub hilite {
  my $arr = shift;
  my @hilite = @_;

  # If neighbor array ref, deref
  if (@hilite == 1 && ref($hilite[0])) {
    @hilite = @{$hilite[0]};
  }

  # If the array is raw coords turn into array of [row, col]
  if (@hilite && !ref($hilite[0])) {
    my $h1 = $hilite[0];
    if ($h1 =~ /^\d+,\d+$/o) {
      # "row,col"
      @hilite = map {/^(\d+),(\d+)$/o; [$1,$2]} @hilite;
    } else {
      # row, col, row, col
      @hilite = pairs(@hilite);
    }
  }

  my %hilite;
  for my $h (@hilite) {
    my ($r, $c) = @$h;
    $hilite{"$r,$c"}++;
  }

  my $maxlen = 0;
  for my $r (@$arr) {
    for my $c (@$r) {
      $maxlen=length($c) if length($c) > $maxlen;
    }
  }
  for my $r (0..$#$arr) {
    my $ra = $arr->[$r];
    for my $c (0..$#$ra) {
      my $v = $ra->[$c];
      print BOLD . ON_RED if $hilite{"$r,$c"};
      printf("%${maxlen}s", $v);
      print RESET;
    }
    print "\n";
  }
  print "\n";
}

# Output a 2d array as text, pad based on longest entry
sub oarr {
  my $arr = \@_;
  unless ($#_) {
    $arr=$_[0];
  }
  return hilite($arr);
}

# Find neighbors
# input
#     neigh_arr, arr, row, col
# OR: neigh_arr, arr, "row,col"
# OR: neigh_arr, rows, cols, row, col
# OR: neigh_arr, rows, cols, "row,col"
# returns
#     array of [row, col, value]
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

# Search/find a rectangle boundary
# Args:
#   array, row 1, col 1, row 2, col 2
# Output:
#   array of [row, col, value]
sub rect {
  my ($array, $r1, $c1, $r2, $c2) = @_;
  my $maxrow = $#$array;
  my $maxcol = $#{$array->[0]};
  ($r1, $r2) = ($r2, $r1) if ($r1 > $r2);
  ($c1, $c2) = ($c2, $c1) if ($c1 > $c2);
  my @out;

  #Horizontal portions
  for my $c ($c1..$c2) {
    next if ($c < 0 || $c > $maxcol);
    if ($r1 <= $maxrow && $r1 >= 0) {
      push @out, [$r1, $c, $array->[$r1][$c]];
    }
    next if ($r1 == $r2);
    if ($r2 <= $maxrow && $r2 >= 0) {
      push @out, [$r2, $c, $array->[$r2][$c]];
    }
  }

  # Vertical portions
  if ($r1 + 1 < $r2) {
    for my $r ($r1+1 .. $r2-1) {
      next if ($r < 0 || $r > $maxcol);
      if ($c1 <= $maxcol && $c1 >= 0) {
        push @out, [$r, $c1, $array->[$r][$c1]];
      }
      next if ($c1 == $c2);
      if ($c2 <= $maxcol && $c2 >= 0) {
        push @out, [$r, $c2, $array->[$r][$c2]];
      }
    }
  }

  return @out;
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

my $dirs = <>;
chomp $dirs;
my @dirs = split('', $dirs);

<>;

while (<>) {
  chomp;
  last unless $_;
  m{(\w+) = \((\w+), (\w+)\)};
  $H{$1}{L} = $2;
  $H{$1}{R} = $3;
}

sub cycle {
  my $n = shift;
  my $n0=$n;
  my @d = @dirs;
  my %seen;
  my $i=0;
  my @zeen;
  while  (!$seen{$n.($i % @dirs)}) {
    $seen{$n.($i % @dirs)}=$i+1;
    if ($n =~ /Z$/) {
      push @zeen, $i;
    }
    $i++;
    my $d = shift @d;
    $n = $H{$n}{$d};
    push @d, $d;
  }
  my $delta = $seen{$n.($i % @dirs)}-1;
  my $cylen = ($i - $delta);
  die "Cycle without Z :(\n" unless @zeen;
  @zeen = grep {$_ >= $delta } @zeen;
  @zeen = map {$_ % $cylen} @zeen;
  say "cycle($n0): cylen = $cylen delta = $delta zeen = ",join(',', @zeen);
  return ($cylen, $delta, @zeen);
  # cycle, delta, zeen
}

$|=1;

out((cycle('AAA'))[2]);

sub split_factor {
  my $mod = shift;
  my @out;
  for my $fe (factor_exp($mod->modulus)) {
    my ($p, $e) = @$fe;
    my $pe = $p ** $e;
    push @out, [$mod->residue % $pe, $p, $e];
  }
  return @out;
}


sub compatible {
  my ($p, $er1, $er2) = @_;
  my $minE = min($er1->[0], $er2->[0]);
  my $modulus = $p ** $minE;
  return $er1->[1] % $modulus == $er2->[1] % $modulus;
}

sub ext_cr {
  my @mods = @_;
  @mods = map { split_factor($_) } @mods;
  my %primes;
  for my $m (@mods) {
    my ($res, $p, $e) = @$m;
    my $newval = [$e, $res];
    if (my $oldval = $primes{$p}) {
      if (compatible($p, $oldval, $newval)) {
        if ($e > $oldval->[0]) {
          $primes{$p} = $newval;
        }
      } else {
        return undef;  # incompatible
      }
    } else {
      $primes{$p} = $newval;
    }
  }
  @mods = ();
  while (my ($p, $er) = each %primes) {
    push @mods, mod($er->[1], ($p ** $er->[0]));
  }
  #say join(',', @mods);
  return cr_combine(@mods);
}

memoize('ext_cr');

my @xs = grep {/A$/} keys %H;
my @cycles = map {[cycle($_)]} @xs;

out (\@cycles);

my @residues;
my @moduli;
my $maxdelta = 0;

for my $cy (@cycles) {
  my ($modulus, $delta, @residue_set) = @$cy;
  push @moduli, $modulus;
  push @residues, \@residue_set;
  $maxdelta = $delta if ($delta > $maxdelta);
}

my $min_ans;

say "number of cases = ", product(map {scalar(@$_)} @residues);

cartesian {
  #say "[",join(',', @_),"]";
  my @mods;
  for my $z (zip(\@_, \@moduli)) {
    push @mods, mod(@$z);
  }
  my $ans = ext_cr(@mods);
  return unless defined($ans);
  my $res = $ans->residue;
  while ($res < $maxdelta) {
    $res += $ans->modulus;
  }
  if (!defined($min_ans) || $res < $min_ans) {
    $min_ans = sprintf("%s",$res);
    say($min_ans);
  }
} @residues;

out($min_ans);