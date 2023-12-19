#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Storable qw(dclone);

say "digraph d19 {";
say "in;";
while (<>) {
  chomp;
  last unless $_;
  my ($n,$w) = m%(\w+)\{(.+)\}$% or die;
  my @lab;
  for my $r (split(',', $w)) {
    my ($c,$op,$v,$nw) = $r =~ /^(?:(.)(.)(\d+):)?(\w+)$/o or die;
    push @lab, "$c$op$v" if $c;
    say " $n -> $nw [label = \"".join(", ", @lab)."\"]";
    if ($c) {
      $op =~ tr/<>/></;
      $lab[-1] = "$c$op=$v";
    }
  }
}

say "}";
