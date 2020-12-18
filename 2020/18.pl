#!/usr/bin/perl -w
use strict;
use feature 'say';

sub myeval2 {
  local $_ = @_ ? shift : $_;
  while (s{\(([^\(\)]+)\)}{myeval2($1)}goe) {};
  while (s{(\d+ \+ \d+)}{eval($1)}oe) {};
  while (s{(\d+ \* \d+)}{eval($1)}oe) {};
  return $_;
}

sub myeval1 {
  local $_ = @_ ? shift : $_;
  while (s{\(([^\(\)]+)\)}{myeval1($1)}goe) {};
  while (s{(\d+ [\+\*] \d+)}{eval($1)}oe) {};
  return $_;
}

my $res1 = 0;
my $res2 = 0;
while(<>) {
  chomp;
  $res1 += myeval1;
  $res2 += myeval2;
}

say $res1;
say $res2;
