#!/usr/bin/perl -w
use strict;

my $c = 0;

my $qc = 0;

my %Q;

sub onEnd {
  for my $v (values(%Q)) {
    $c++ if ($v==$qc);
  }
  %Q = (); $qc = -1;
}

while (<>) {
  print;
  chomp;
  for  my $x (split('', $_)) {
    $Q{$x}++;
  }
  if (m/^$/o) {
    onEnd();
  }
  $qc++;
}

onEnd();

print "$c\n";
