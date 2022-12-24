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
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use Time::HiRes qw(usleep);

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
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
my @VORT=(\@A);

my $start = "0,0,0,0";

sub end {
  my $step = shift;
  return sub {
    my $node = shift;
    my $megastep = (split(',', $node))[-1];
    return $megastep==$step;
  }
}

my @VHASH;

sub vort {
  my $step = shift;
  unless ($VORT[$step]) {
    my $prevvort = $VORT[$step-1];
    my @vortex = @$prevvort;
    for my $v (@vortex) {
      my ($r,$c,$rd,$cd) = @$v;
      $r+=$rd; $c+=$cd;
      $r=1 if $r == $rl;
      $r=$rl-1 if $r == 0;
      $c=0 if $c == $cl;
      $c=$cl-1 if $c < 0;
      $v = [$r,$c,$rd,$cd];
    }
    $VORT[$step] = \@vortex;
  }
  unless ($VHASH[$step]) {
    my %V;
    for my $v (@{$VORT[$step]}) {
      my ($vr,$vc) = @$v;
      $V{$vr,$vc}++;
    }
    $VHASH[$step]=\%V;
  }
  return $VHASH[$step];
}

sub nneigh {
  my $node = shift;
  my ($r,$c,$step,$megastep) = split(',', $node);
  $step++;
  my $V = vort($step);
  my @options;
  push @options, "$r,$c,$step,$megastep" unless $V->{$r,$c};
  for my $d (values %DIRS) {
    my ($nr,$nc) = ($r,$c);
    my ($dr,$dc) = @$d;
    $nr+=$dr;
    $nc+=$dc;
    next if $V->{$nr,$nc};
    next if $nc < 0;
    next if $nc >= $cl;
    next if ($nr < 0 || $nr > $rl);
    next if ($nr == 0 && $nc != 0);
    next if ($nr == $rl && $nc != $cl-1);
    if ($nr==$rl && ($megastep&1) == 0 || $nr == 0 && ($megastep&1) == 1) {
      push @options, "$nr,$nc,$step,".($megastep+1);
    } else {
      push @options, "$nr,$nc,$step,$megastep";
    }
  }
  return @options;
}

sub viz {
  my $node = shift;
  my ($er,$ec,$step) = split(',', $node);
  my $V = vort($step);
  my $E = BOLD . ON_RED . 'E'. RESET;
  if ($er == 0) {
    say ("#$E" . ('#' x $cl));
  } else {
    say ('#.' . ('#' x $cl));
  }
  for my $r (1..$rl-1) {
    print '#';
    for my $c (0..$cl-1) {
      if ($r == $er && $c == $ec) {
        print "$E";
        next;
      }
      print $V->{$r,$c} || '.';
    }
    say '#';
  }
  if ($er == $rl) {
    say (('#' x $cl) . "$E#");
  } else {
    say (('#' x $cl) . '.#');
  }
}

#sub heuristic {
#  my $node = shift;
#  my ($r,$c) = split(',', $node);
#  return $cl-$c-1 + $rl-$r;
#}

#out([astar($start,end(1),\&nneigh)]);
my ($res,@path) = astar($start,end(3),\&nneigh);
out ($res);
print "\033[2J";    #clear the screen
for my $p (@path) {
  print "\033[0;0H"; #jump to 0,0  say "$p";
  viz($p);
  Time::HiRes::sleep(0.1);
}