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

sub scan {
  my $w = shift;
  my $cond = shift;

  if ($w eq 'R') {
    return 0;
  } elsif ($w eq 'A') {
    my $res = product(map {$_->[1]-$_->[0]+1} values(%$cond));
    return $res;
  }

  my $res = 0;
  my @w = @{$H{$w}};
  for my $st (@w) {
    my ($c,$op,$n,$nw) = $st =~ /^(?:(.)(.)(\d+):)?(\w+)$/o or die;
    if (!defined($c)) {
      $res += scan($nw,$cond);
      last;
    }
    if ($op eq '<') {
      my $ncond = dclone($cond);
      $ncond->{$c}[1] = min($cond->{$c}[1],$n-1);
      if ($ncond->{$c}[1] < $ncond->{$c}[0]) {
        next;
      }
      $res += scan($nw, $ncond);
      $cond->{$c}[0] = max($cond->{$c}[0],$n);
    } else {
      my $ncond = dclone($cond);
      $ncond->{$c}[0] = max($cond->{$c}[0],$n+1);
      if ($ncond->{$c}[1] < $ncond->{$c}[0]) {
        next;
      }
      $cond->{$c}[1] = min($cond->{$c}[1],$n);
      $res += scan($nw, $ncond);
    }
    if ($cond->{$c}[1] < $cond->{$c}[0]) {
      last;
    }
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
  chop;
  $_=substr($_,1);
  my %v;
  for my $a (split(',')) {
    my ($x,$v) = split('=', $a);
    $v{$x}=$v;
  }
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
out(scan('in',{'x', [1,4000], 'm', [1,4000], 'a', [1,4000], 's', [1,4000]}));
