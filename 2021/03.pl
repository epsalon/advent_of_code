#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;
use Math::Complex;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my @A;

my @L;

while (<>) {
    chomp;
    my @l = split('');
    push @L, \@l;
    for (my $i=0; $i <=$#l; $i++) {
      $A[$i]++ if $l[$i];
      $A[$i]-- unless $l[$i];
    }
}

my $g = oct("0b".join('', map {$_ > 0 ? 1 : 0} @A));
my $e = oct("0b".join('', map {$_ > 0 ? 0 : 1} @A));

out $g*$e;

my @L2 = @L;

my $d = 0;
while (@L > 1) {
  my $tc;
  for my $b (@L) {
    $tc++ if $b->[$d];
    $tc-- unless $b->[$d];
  }
  my $td = $tc >= 0 ? 1 : 0;
  @L = grep {$_->[$d] == $td} @L;
  print "d=$d td=$td tc=".$tc." L=".join(';', map {join ('', @$_)} @L),"\n";
  $d++;
}

my $a = oct("0b".join('',@{$L[0]}));

$d = 0;
@L = @L2;
while (@L > 1) {
  my $tc;
  for my $b (@L) {
    $tc++ if $b->[$d];
    $tc-- unless $b->[$d];
  }
  my $td = $tc < 0 ? 1 : 0;
  @L = grep {$_->[$d] == $td} @L;
  print "d=$d td=$td tc=".$tc." L=".join(';', map {join ('', @$_)} @L),"\n";
  $d++;
}

my $b = oct("0b".join('',@{$L[0]}));

out "$a $b";
out $a*$b;
