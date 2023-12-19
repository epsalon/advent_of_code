#!/usr/bin/perl -w
use strict;
use feature 'say';
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Storable qw(dclone);

my %H;

# Split a semi-open range [min,max) at value.
sub split_range {
  my ($min, $max, $value) = @_;
  if ($value <= $min) {
    return (undef, [$min,$max]);
  } elsif ($value >= $max) {
    return ([$min,$max], undef);
  }
  return ([$min,$value], [$value,$max]);
}

# Follow the workflow tree and count accepted cases
sub scan {
  my $w = shift;     # Current workflow
  my $cond = shift;  # hash from key to [min,max) for that key

  return 0 if ($w eq 'R');
  return product(map {$_->[1]-$_->[0]} values(%$cond)) if ($w eq 'A');

  my $res = 0;
  for my $st (@{$H{$w}}) {
    my ($c,$op,$n,$nw) = $st =~ /^(?:(.)(.)(\d+):)?(\w+)$/o or die;
    # Unconditional jump
    if (!defined($c)) {
      $res += scan($nw,$cond);
      last;
    }
    # Condition, correct for > not being >=
    my ($lo,$hi) = split_range(@{$cond->{$c}}, $n + ($op eq '>'));
    # Recurse when condition is true
    my $ncond = dclone($cond);
    $ncond->{$c} = ($op eq '<' ? $lo : $hi) or next;
    $res += scan($nw, $ncond);
    # Loop when condition is false
    $cond->{$c} = ($op eq '<' ? $hi : $lo) or last;
  }
  return $res;
}

# Read workflows
while (<>) {
  chomp;
  last unless $_;
  my ($n,$w) = m%(\w+)\{(.+)\}$% or die;
  $H{$n} = [split(',',$w)];
}

# Solve part 1
my $sum=0;
while (<>) {
  chomp;
  last unless $_;
  ($_) = m%^{(.*)}$%;
  my %v = map {split('=', $_)} split(',');
  # Follow workflow, @w is remaining actions.
  my @w = @{$H{'in'}};
  while (@w) {
    my $st = shift @w;
    my ($c,$op,$n,$nw) = $st =~ /^(?:(.)(.)(\d+):)?(\w+)$/o or die;
    if (!defined($c) || eval ($v{$c}." $op $n")) {
      if ($nw eq 'A') {
        $sum += sum(values %v);
        last;
      }
      if ($nw eq 'R') {
        last;
      }
      @w = @{$H{$nw}};
    }
  }
}
say $sum;

# Part 2 with initial map
say scan('in',{map {$_ => [1,4001]} qw/x m a s/});
