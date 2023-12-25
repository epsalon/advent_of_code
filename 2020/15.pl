#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

$_=<>;
chomp;
my @A = split(/,/);

my $prev = pop @A;

my $N=1;

my @LASTIDX;
for my $a (@A) {
  $LASTIDX[$a]=$N;
  $N++;
}

BIG: while ($N < 30000000) {
  #say "$N" unless ($N % 1000000);
  my $prevn = $LASTIDX[$prev];
  #say "prev=$prev";
  $LASTIDX[$prev] = $N;
  #say "lastn=$lastn prevn=$prevn";
  if (!defined($prevn)) {
    $prev = 0;
  } else {
    #say "prevn = $prevn N = $N";
    $prev = $N-$prevn;
  }
  $N++;
}

out ($prev);
