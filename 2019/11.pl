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
  #return ($str =~ m{[a-zA-Z]+|\d+}go);
  return ($str =~ m{\d+}go);
}

sub hashify {
  my @arr = ref $_[0] ? @{$_[0]} : @_;
  return map {$_ => 1} @arr;
}
my $in;
while (<>) {
  chomp;
  $in.=$_;
}

sub get_mem_ptr {
  my ($mem, $addr) = @_;
  unless ($mem->{$addr}) {
    $mem->{$addr} = 0;
  }
  return \($mem->{$addr});
}

# returns array of refs
sub do_mode {
  my ($mode, $operand, $MEM, $base) = @_;
  my @mode = split('',$mode);
  my @out;
  for my $o (@$operand) {
    my $m = pop(@mode) || 0;
    if ($m == 0) {
      push @out, get_mem_ptr($MEM,$o);
      #say "using mode 0 (indirect) for operand $o";
    } elsif ($m == 1) {
      push @out, \$o;
      #say "using mode 1 (immediate) for operand $o";
    } elsif ($m == 2) {
      push @out, get_mem_ptr($MEM,$o+$base);
      #say "using mode 2 (index) for operand $o, base = $base";
    } else {
      die;
    }
  }
  return @out;
}

my @OPERATIONS = qw/0 3 3 1 1 2 2 3 3 1/;

sub outprog {
  my $p = shift;
  for my $pc (nsort(keys(%$p))) {
    printf "%04d: %d\n", $pc, $p->{$pc};
  }
}

sub run {
  my $OPROG = shift;
  my $pc = 0;
  my $base = 0;
  if (ref($OPROG) eq 'ARRAY') {
    ($OPROG,$pc,$base) = @$OPROG;
  }
  my %PROG = %$OPROG;
  my $IN = shift || [];
  my @out;
  while (${get_mem_ptr(\%PROG, $pc)} != 99) {
    my $op = $PROG{$pc};
    my $mode = int($op / 100);
    $op = $op % 100;
    my $oplen = $OPERATIONS[$op];
    #say "pc=$pc op=$op mode=$mode oplen=$oplen";
    my @oplist;
    for my $i ($pc+1..$pc+$oplen) {
      push @oplist, ${get_mem_ptr(\%PROG, $i)};
    }
    #out(\@oplist);
    my @operands = do_mode($mode, \@oplist, \%PROG, $base);
    #out (\@operands);
    if ($op == 1) {
      #say "[".$operands[2]."] <- ".${$operands[0]}." + ".${$operands[1]};
      ${$operands[2]} = ${$operands[0]} + ${$operands[1]};
    } elsif ($op == 2) {
      ${$operands[2]} = ${$operands[0]} * ${$operands[1]};
    } elsif ($op == 3) {
      unless (@$IN) {
        return \@out, [\%PROG, $pc, $base];
      }
      ${$operands[0]} = (shift @$IN);
    } elsif ($op == 4) {
      push @out, ${$operands[0]};
    } elsif ($op == 5) {
      if (${$operands[0]}) {
        $pc = ${$operands[1]};
        next;
      }
    } elsif ($op == 6) {
      unless (${$operands[0]}) {
        $pc = ${$operands[1]};
        next;
      }
    } elsif ($op == 7) {
      ${$operands[2]} = ${$operands[0]} < ${$operands[1]};
    } elsif ($op == 8) {
      ${$operands[2]} = ${$operands[0]} == ${$operands[1]};
    } elsif ($op == 9) {
      $base += ${$operands[0]};
    } else {
      die;
    }
    $pc += $oplen + 1;
  }
  #outprog(\%PROG);
  return \@out, 0;
}

my @IN = split(/,/, $in);
my %IN;
for my $i (0..$#IN) {
  $IN{$i} = $IN[$i];
}

sub viz {
  my $R = shift;
  my %MAP = qw/0 . 1 # 2 X/;
  my ($minx,$miny,$maxx,$maxy) = (999,999,0,0);
  while (my($p,$v) = each %$R) {
    next unless $v;
    my ($x,$y) = split($;, $p);
    $minx = $x if $minx > $x;
    $miny = $y if $miny > $y;
    $maxx = $x if $maxx < $x;
    $maxy = $y if $maxy < $y;
  }
  #print "\033[0;0H";

  say "$minx $miny $maxx $maxy    ";

  for my $y ($miny..$maxy) {
    for my $x ($minx..$maxx) {
      print $MAP{$R->{$x,$y} || 0};
    }
    print "\n";
  }
  print "\n";
}

sub runbot {
  my $R = shift;
  my $rloc = 0;
  my $rdir = -i;

  my @outbuf;

  my ($out,$cont) = run(\%IN);
  push @outbuf, @$out;
  while ($cont) {
    ($out,$cont) = run($cont, [$R->{Re($rloc),Im($rloc)} || 0]);
    push @outbuf, @$out;
    while (@outbuf) {
      my ($color,$dir) = splice(@outbuf,0,2);
      $R->{Re($rloc),Im($rloc)} = $color;
      die if ($dir && $dir != 1);
      $rdir *= ($dir?i:-i);
      $rloc+=$rdir;
      my $v = $R->{Re($rloc),Im($rloc)} || 0;
      $R->{Re($rloc),Im($rloc)} = 2;
      viz($R);
      $R->{Re($rloc),Im($rloc)} = $v;
    }
  }
}

#my %R1;
#runbot(\%R1);
#out(scalar(%R1));

my %R;
$R{0,0} = 1;
runbot(\%R);
