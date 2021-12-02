#!/usr/bin/perl -w
use strict;
use feature 'say';
use Data::Dumper;
use ntheory qw/chinese/;

my $time = <>;
chomp $time;

$_ = <>;
chomp;

my @C;

my $i=0;
for my $bus (split(/,/)) {
  next unless $bus =~ /^\d+$/;
  push @C, [($bus - $i) % $bus, $bus];
} continue {
  $i++;
}

print Dumper(\@C);
say chinese(@C);