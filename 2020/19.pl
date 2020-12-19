#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my @RULES;

sub expand {
  my $rule = shift;
  while ($rule =~ s/(\d+)/"(?:".$RULES[$1].")"/goe) {}

  $rule =~ s/\s+//go;
  $rule =~ s/\"//go;
  return $rule;
}

my $res = 0;
while(<>) {
  chomp;
  last if /^$/;
  m{(\d+): (.+)}o or die;
  $RULES[$1]=$2;
}

#comment these for part1
$RULES[8] = "(?: 42 )+";
$RULES[11] = "(42 (?___)* 31)";

my $rule = expand($RULES[0]);

say $rule;

$rule =~ s/___/1/go;
$rule = "^(?:$rule)\$";

say $rule;

while (<>) {
  chomp;
  if (/$rule/) {
    $res++;
  }
}

out ($res);
