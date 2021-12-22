#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use feature 'say';
use Clipboard;
use List::Util qw/sum max min/;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

my @A;

sub printlist {
  say join('; ', map {join(',', @$_)} @_), " => ", sum(map {volume($_)} @_);
}

sub prismdiff {
  my ($p1,$p2) = @_;
  $p1 = [@$p1];
  $p2 = [@$p2];
  my @out;
  my @prefix;
  while (@$p1) {
    my ($s1,$e1,$s2,$e2) = (shift @$p1, shift @$p1, shift @$p2, shift @$p2);
    if ($s1 < $s2) {
      push @out,[@prefix, $s1,min($e1,$s2), @$p1];
    }
    if ($e2 < $e1) {
      push @out,[@prefix, max($s1,$e2),$e1, @$p1];
    }
    my $x1 = max($s1, $s2);
    my $x2 = min($e1, $e2);
    unless ($x1 < $x2) {
      return $_[0];
    }
    last unless @$p1;
    push @prefix, ($x1, $x2);
  }
  return @out;
}

sub volume {
  my $p = shift;
  my @p = @$p;
  my $ret = 1;
  while (@p) {
    $ret *= (-(shift @p) + (shift @p));
  }
  return $ret;
}

while (<>) {
  chomp;
  my ($state, $rest) = m{(on|off)[^\d-]+(.+)$};
  $state = ($state eq 'on');
  my @p = split(/[^\d-]+/, $rest);
  $p[1]++; $p[3]++; $p[5]++;
  @A = map {prismdiff($_, \@p)} @A;
  if ($state) {
    push @A, \@p;
  }
  #out (sum(map {volume($_)} @A));  
}

out (sum(map {volume($_)} @A));