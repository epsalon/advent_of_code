#!/usr/bin/perl -w
use strict;

my $c = 0;

my $qc = 0;

my %Q;

while (<>) {
  chomp;
  for  my $x (split('', $_)) {
    $Q{$x}++;
  }
  $qc++;
  if (m/^$/o) {
    for my $v (values(%Q)) {
      $c++ if ($v==$qc-1);
    }
    %Q = (); $qc = 0;
  }
}

print "$c\n";
