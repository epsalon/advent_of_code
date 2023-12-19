#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Storable qw(dclone);

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}

$|=1;

my @A;
my %H;

sub split_range {
  my ($min, $max, $value) = @_;
  if ($value <= $min) {
    return (undef, [$min,$max]);
  } elsif ($value >= $max) {
    return ([$min,$max], undef);
  }
  return ([$min,$value], [$value,$max]);
}

sub scan {
  my $w = shift;
  my $cond = shift;

  return 0 if ($w eq 'R');
  return product(map {$_->[1]-$_->[0]} values(%$cond)) if ($w eq 'A');

  my $res = 0;
  my @w = @{$H{$w}};
  for my $st (@w) {
    my ($c,$op,$n,$nw) = $st =~ /^(?:(.)(.)(\d+):)?(\w+)$/o or die;
    if (!defined($c)) {
      $res += scan($nw,$cond);
      last;
    }
    my ($lo,$hi) = split_range(@{$cond->{$c}}, $n + ($op eq '>'));
    my $ncond = dclone($cond);
    $ncond->{$c} = ($op eq '<' ? $lo : $hi) or next;
    $res += scan($nw, $ncond);
    $cond->{$c} = ($op eq '<' ? $hi : $lo) or last;
  }
  return $res;
}

while (<>) {
  chomp;
  last unless $_;
  my ($n,$w) = m%(\w+)\{(.+)\}$% or die;
  $H{$n} = [split(',',$w)];
}

my $sum=0;

while (<>) {
  chomp;
  last unless $_;
  ($_) = m%^{(.*)}$%;
  my %v = map {split('=', $_)} split(',');
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

out ($sum);
out(scan('in',{map {$_ => [1,4001]} qw/x m a s/}));
