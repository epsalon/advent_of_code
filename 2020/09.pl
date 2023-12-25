#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my @prev;

sub chk {
  for my $i (0..$#prev-1) {
    for my $j ($i..$#prev) {
      if ($_ == $prev[$i] + $prev[$j]) {
        return 1;
      }
    }
  }
  return 0;
}

my @arr;
my $res;

while (<>) {
  chomp;
  push @arr, $_;
  if (@prev == 25) {
    unless (chk()) {
      print "RESULT = $_\n";
      $res = $_ unless $res;
    }
  }
  push @prev, $_;
  if (@prev > 25) {
    shift @prev;
  }
}

for my $i (0..$#arr-1) {
  my $sum = $arr[$i];
  my $min = $sum;
  my $max = $sum;
  for my $j ($i+1..$#arr) {
    if ($arr[$j] > $max) {
      $max=$arr[$j];
    }
    if ($arr[$j] < $min) {
      $min=$arr[$j];
    }
    $sum += $arr[$j];
    if ($sum == $res) {
      print "i=$i j=$j sum=$sum\n";
      print $min+$max,"\n";
      exit;
    }
    if ($sum > $res) {
      last;
    }
  }
}
