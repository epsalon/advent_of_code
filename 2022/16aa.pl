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
  return ($str =~ m{[A-Z]{2}|\d+}go);
}

sub hashify {
  my @arr = ref $_[0] ? @{$_[0]} : @_;
  return map {$_ => 1} @arr;
}

my %H;

while (<>) {
  chomp;
  last unless $_;
  my @p = smart_split();
  out(\@p);
  my $v = shift(@p);
  my $r = shift(@p);
  my @c = @p;
  $H{$v} = [$r,@c];
}

out(\%H);


# node
# [curr room],time,[open valves]
# -> open valve (cost -c)
# -> go to room


sub solve {
my ($length, $loops) = @_;
my $sum=0;
my $tt=0;

*nnn = sub {
  my $node = shift;
  my ($t,$r,@ov) = split(',',$node);
  if ($t == $length * $loops) {
    return ();
  }
  $t++;
  if ($t > $tt) {
    say "t=$t";
    $tt=$t;
  }
  my $tr = $t % $length;
  #say "node=$node tr=$tr";
  unless ($tr) {
    return ["$t,".join(",", "AA", @ov), 0];
  }
  my %ovh = hashify(@ov);
  my @out;
  my @vd = @{$H{$r}};
  my $vr = shift(@vd);

  for my $n (@vd) {
    #say "  [$t] $r => $n";
    push @out,[("$t,".join(',',$n,@ov)), 0];
  }
  if (!$ovh{$r} && $vr > 0) {
    push @ov, $r;
    @ov=sort(@ov);
    push @out,[("$t,".join(',',$r,@ov)), -($length-$tr)*$vr];
  }

  return @out;
};

#my %path = ("0,AA", []);
my %N = ("0,AA", 0);
my $OPEN = new List::PriorityQueue;
$OPEN->insert("0,AA", 0);
my %OHASH = ("0,AA", 1);
#my $bp;

while (%OHASH) {
  my $n = $OPEN->pop();
  my $c = $N{$n};
  my ($t) = split(',',$n);
  #my $pat = $path{$n};
  if ($c < $sum) {
    $sum = $c;
    #$bp = $pat;
    say "$sum";
    say "open size = ".scalar(%OHASH);
  }
  #say "n=$n c=$c sum=$sum";
  delete $OHASH{$n};
  NL: for my $n (nnn($n)) {
    my ($n2,$dc) = @$n;
    if (!defined($N{$n2}) || $N{$n2} > ($c + $dc)) {
      my $n2x = ($n2 =~ /\d+,(.*)$/o);
      my $n2xi = ($t-1).",$n2x";
      if (defined ($N{$n2xi}) && $N{$n2xi} < ($c + $dc)) {
        next NL;
      }
      $N{$n2} = ($c + $dc);
      #$path{$n2} = [$n2, @$pat];
      if (!$OHASH{$n2}) {
        $OPEN->insert($n2, $N{$n2});
        $OHASH{$n2}++;
      }
    }
  }  
}

#out($bp);

return (-$sum);
}

out(solve(30,1));
out(solve(26,2));
