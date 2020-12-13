#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use ntheory qw/chinese/;

my $time = <>;
chomp $time;

$_ = <>;
chomp;

my @C;

my $i=0;
for my $bus (split(/,/)) {
  $i++;
  next unless $bus =~ /^\d+$/;
  push @C, [($bus - $i) % $bus, $bus];
}

print Dumper(\@C);
print chinese(@C) + 1, "\n";