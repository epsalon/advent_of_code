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

$| = 1;

while (<>) {
  chomp;
  last unless $_;
  push @A, split(' ');
}

sub run_machine {
  my @input = @_;
  my @stack;
  for my $l (@A) {
    say 'STACK= '.join('; ', map {join(',', @$_)} @stack);
    say $l;
    unless ($l =~ /[a-z]+/) {
      push @stack, [$l, $l];
      next;
    }
    if ($l eq 'var') {
      my $sv = pop @stack;
      my $input = $input[$sv->[0] - 1];
      push @stack, $input;
      next;
    }
    my $opcode = $l;
    my $oth = pop @stack;
    my $acc = pop @stack;
    my %vals_res;
    if ($opcode eq 'add') {
      for my $a (@$acc) {
        for my $o (@$oth) {
          $vals_res{$a + $o} = 1;
        }
      }
    } elsif ($opcode eq 'mul') {
      for my $a (@$acc) {
        for my $o (@$oth) {
          $vals_res{$a * $o} = 1;
        }
      }
    } elsif ($opcode eq 'div') {
      for my $a (@$acc) {
        for my $o (@$oth) {
          $vals_res{int ($a/$o)} = 1;
        }
      }
    } elsif ($opcode eq 'mod') {
      for my $a (@$acc) {
        for my $o (@$oth) {
          $vals_res{$a%$o} = 1;
        }
      }
    } elsif ($opcode eq 'eql') {
      for my $a (@$acc) {
        for my $o (@$oth) {
          $vals_res{$a == $o ? 1 : 0} = 1;
        }
      }
    }
    if (%vals_res > 1000) {
      %vals_res = ();
    }
    push @stack, [keys(%vals_res)];
  }
  my $out = pop(@stack);
  die if @stack;
  return @$out;
}


my @out = run_machine (map {[$_]} (split('', 92915979999499 - 1)));

print Dumper(\@out);

exit;

my @prefix = split('', '999959');

BIGLOOP: while (@prefix < 14) {
  say "PREFIX = ".join('', @prefix);
  my @input1 = map {[$_]} (@prefix);
  my @input2 = map {[1..9]} (@prefix..14);
  my @input = (@input1, @input2);

  my @output = run_machine(@input);

  push @output, 0 unless @output;

  for my $v (@output) {
    unless ($v) {
      #print Dumper($VARS{'z'});
      #say "YES";
      push @prefix, 9;
      #say "NEW PREFIX = ", join('', @prefix);
      next BIGLOOP;
    }
  }
  my $v = 0;
  while (!$v) {
    $v = pop(@prefix);
    $v--;
  }
  push @prefix, $v;
}

out join('', @prefix);