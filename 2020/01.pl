#!/usr/bin/perl -w
use strict;

my %SEEN;

while (<>) {
  chomp;
  if ($SEEN{2020-$_}) {
    print "two: ".($_ * (2020-$_)."\n");
  }
  $SEEN{$_}++;
}


for my $v1 (keys %SEEN) {
  for my $v2 (keys %SEEN) {
    if ($v1 > $v2) {
      if ($SEEN{2020-$v1-$v2}) {
        print "three: ".($v1 * $v2 * (2020-$v1-$v2)."\n");
        exit;
      }
    }
  }  
}
