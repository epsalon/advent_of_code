#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my @A;

while (<>) {
  #print;
  chomp;
  push @A, $_;
}

my $s=0;
for (my $i=0; $i < @A - 3; $i++) {
  $s++ if $A[$i] < $A[$i+3];
}

print "$s\n";
