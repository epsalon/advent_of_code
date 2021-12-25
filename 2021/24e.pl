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
  push @A, [split(' '), ''];
}

sub run_machine {
  my @input = @_;
  my %VARS = ('w', [0,0], 'x', [0,0], 'y', [0,0], 'z', [0,0]);
  for my $l (@A) {
    #print Dumper(\%VARS);
    my ($opcode, $acc, $oth) = @$l;
    my ($exp_acc, @vals_acc) = @{$VARS{$acc}};
    my (@vals_oth);
    if (defined($VARS{$oth})) {
      ($oth, @vals_oth) = @{$VARS{$oth}};
    } else {
      $oth = 0 unless $oth;
      @vals_oth = ($oth);
    }
    my $acc_zero = (@vals_acc == 1 && $vals_acc[0] == 0);
    my $oth_zero = (@vals_oth == 1 && $vals_oth[0] == 0);
    my $acc_one = (@vals_acc == 1 && $vals_acc[0] == 1);
    my $oth_one = (@vals_oth == 1 && $vals_oth[0] == 1);
    my %vals_res;
    my $exp;
    if ($opcode eq 'inp') {
      $VARS{$acc} = shift @input;
      next;
    } elsif ($opcode eq 'add') {
      $exp = ($acc_zero ? $oth : (
        $oth_zero ? $exp_acc :
        ['add',$exp_acc,$oth]
      ));
      for my $a (@vals_acc) {
        for my $o (@vals_oth) {
          $vals_res{$a + $o} = 1;
        }
      }
    } elsif ($opcode eq 'mul') {
      next if ($oth_one);
      $exp = ($acc_zero ? 0: (
        $oth_zero ? 0 :
        ['mul',$exp_acc,$oth]
      ));
      $exp = $oth if $acc_one;
      for my $a (@vals_acc) {
        for my $o (@vals_oth) {
          $vals_res{$a * $o} = 1;
        }
      }
    } elsif ($opcode eq 'div') {
      next if ($oth_one);
      $exp = $acc_zero ? 0 : ['div',$exp_acc,$oth];
      for my $a (@vals_acc) {
        for my $o (@vals_oth) {
          next unless $o;
          $vals_res{int($a/$o)} = 1;
        }
      }
    } elsif ($opcode eq 'mod') {
      $exp = $acc_zero ? 0 : ['mod',$exp_acc,$oth];
      for my $a (@vals_acc) {
        for my $o (@vals_oth) {
          next unless $o;
          $vals_res{$a % $o} = 1;
        }
      }
      if (!@vals_acc) {
        for my $i (0..max(@vals_oth)) {
          $vals_res{$i} = 1;
        }
      }
      $VARS{$acc} = [$exp, keys(%vals_res)];
    } elsif ($opcode eq 'eql') {
      $exp = ['eql',$exp_acc,$oth];
      for my $a (@vals_acc) {
        for my $o (@vals_oth) {
          $vals_res{$a == $o ? 1 : 0} = 1;
        }
      }
    }
    if (%vals_res > 1000) {
      %vals_res = ();
    }
    if (%vals_res == 1) {
      $VARS{$acc} = [(keys(%vals_res)) x 2];
    } else {
      $VARS{$acc} = [$exp, keys(%vals_res)];
    }
  }

  return @{$VARS{'z'}};

}

my @prefix = ();

BIGLOOP: while (@prefix < 14) {
  say "PREFIX = ".join('', @prefix) unless $sum++ & 0xff;
  my @input1 = map {[$_, $_]} (@prefix);
  my @input2 = map {[("x$_", 1..9)]} (@prefix..13);
  my @input = (@input1, @input2);
  #print Dumper(\@input);

  my @output = run_machine(@input);
  print Dumper(\@output);
  exit;

  push @output, 0 if (@output == 1);

  for my $v (@output) {
    unless ($v) {
      #print Dumper($VARS{'z'});
      #say "YES";
      push @prefix, 1;
      #say "NEW PREFIX = ", join('', @prefix);
      next BIGLOOP;
    }
  }
  my $v = 10;
  while ($v == 10) {
    $v = pop(@prefix);
    $v++;
  }
  push @prefix, $v;
}

out join('', @prefix);