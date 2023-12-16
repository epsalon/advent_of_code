#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
# use POSIX;

BEGIN {push @INC, "../lib";}
use Grid::Dense;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    print "$out\n";
  }
}

$|=1;

my @A;
while (my $line = <>) {
    chomp $line;
    last unless $line;
    push @A, [split('', $line)];
}

my $rows = scalar(@A);
my $cols = scalar(@{$A[0]});

my @STACK;
my %STACKHASH;

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
    out($sum); $part1++;
  }
  $sum = max($sum,try("$r,".($cols-1).",0,-1"));
}

for my $c (0..$cols-1) {
  $sum = max($sum,try("0,$c,1,0"));
  $sum = max($sum,try(($rows-1).",$c,-1,0"));
}

out($sum);
#$grid->print(keys %SEEN);

#out (scalar(%SEEN));
