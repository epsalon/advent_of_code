#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my @A;

while (<>) {
  #print;
  chomp;
  push @A, $_;
}

my @jolts = sort {$a <=> $b} @A;

push @jolts, $jolts[$#jolts] + 3;
unshift @jolts, 0;

my $l = 0;

my @C;

my %MEMO;
$MEMO{$#jolts} = 1;

sub cnt {
  my $i = shift;
  return $MEMO{$i} if $MEMO{$i};
  my $sum = 0;
  for my $s (1..3) {
    last if ($i + $s > $#jolts); 
    if ($jolts[$i+$s] - $jolts[$i] <= 3) {
      $sum += cnt($i+$s);
    }
  }
  $MEMO{$i} = $sum;
  return $sum;
}

print cnt(0), "\n";
