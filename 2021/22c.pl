#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use feature 'say';
use Clipboard;
use List::Util qw/sum max min pairs product/;

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

# May destroy p1
sub prismdiff {
  my ($p1,$p2) = @_;
  my @pre;
  for my $i (0..@$p1/2-1) {
    my $x1 = max($p1->[2*$i], $p2->[2*$i]);
    my $x2 = min($p1->[2*$i + 1], $p2->[2*$i + 1]);
    return $p1 unless ($x1 < $x2);
    push @pre, ($x1, $x2);
  }
  my @out;
  my @prefix;
  while (@$p1) {
    my ($s1,$e1,$s2,$e2) = (splice(@$p1,0,2), $p2->[@prefix], $p2->[@prefix+1]);
    if ($s1 < $s2) {
      push @out,[@prefix, $s1, min($e1,$s2), @$p1];
    }
    if ($e2 < $e1) {
      push @out,[@prefix, max($s1,$e2), $e1, @$p1];
    }
    last unless @$p1;
    push @prefix, splice(@pre,0,2);
  }
  return @out;
}

sub volume {
  return product(map {$_->[1] - $_->[0]} pairs(@{$_[0]}));
}

while (<>) {
  chomp;
  my ($state, $rest) = m{(on|off)[^\d-]+(.+)$};
  $state = ($state eq 'on');
  my @p = split(/[^\d-]+/, $rest);
  for my $i (0..@p/2-1) {
    $p[2*$i+1]++;
  }
  @A = map {prismdiff($_, \@p)} @A;
  if ($state) {
    push @A, \@p;
  }
  #out (sum(map {volume($_)} @A));  
}

say "Total: ", scalar(@A), " prisms";
out (sum(map {volume($_)} @A));