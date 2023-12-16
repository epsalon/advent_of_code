#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use feature 'say';
use List::Util qw/max/;

$|=1;

my @A;
while (my $line = <>) {
    chomp $line;
    last unless $line;
    push @A, [split('', $line)];
}

my $rows = scalar(@A);
my $cols = scalar(@{$A[0]});

sub try {
  my @OPEN=@_;
  my %CLOSED;
  my %SEEN;
  while (@OPEN) {
    my $x = shift @OPEN;
    next if ($CLOSED{$x});
    $CLOSED{$x}++;
    my ($r,$c,$rd,$cd) = split(',', $x);
    $SEEN{"$r,$c"}++;
    my $ch = $A[$r][$c];
    if ($ch eq '/') {
      ($rd,$cd) = (-$cd,-$rd);
    } elsif ($ch eq '\\') {
      ($rd,$cd) = ($cd,$rd);
    } elsif ($ch eq '|' && $cd) {
      push @OPEN,"$r,$c,-1,0","$r,$c,1,0";
      next;
    } elsif ($ch eq '-' && $rd) {
      push @OPEN,"$r,$c,0,-1","$r,$c,0,1";
      next;
    }
    $r+=$rd; $c+=$cd;
    next if ($r<0 || $c<0 || $r >= $rows || $c >= $cols);
    push @OPEN,"$r,$c,$rd,$cd";
  }
  return scalar(%SEEN);
}

my $sum=0;
my $part1;

for my $r (0..$rows-1) {
  $sum = max($sum,try("$r,0,0,1"));
  unless ($part1) {
    say($sum); $part1++;
  }
  $sum = max($sum,try("$r,".($cols-1).",0,-1"));
}

for my $c (0..$cols-1) {
  $sum = max($sum,try("0,$c,1,0"));
  $sum = max($sum,try(($rows-1).",$c,-1,0"));
}

say($sum);

