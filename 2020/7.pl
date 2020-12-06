#!/usr/bin/perl -w
use strict;

my $c = 0;

my $qc = 0;

my %Q;

sub onEnd {
  # CODE GOES HERE
  %Q = (); $qc = -1;
}

while (<>) {
  print;
  chomp;
  # CODE GOES HERE
  if (m/^$/o) {
    onEnd();
  }
  $qc++;
}

onEnd();

print "$c\n";
