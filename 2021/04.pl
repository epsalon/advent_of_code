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

$_=<>;
chomp;
my @numbers = split(/,/);

my @cards;

while (<>) {
  my @card;
  for my $i (1..5) {
    my $line = <>;
    chomp $line;
    my @row = split(' ', $line);
    push @card, \@row;
  }
  push @cards, \@card;
}

my @winner;
my $winnum;

LOOP: while (@numbers) {
  my $n = shift(@numbers);
  CARD: for my $card (@cards) {
    next unless $card;
    for my $row (@$card) {
      @$row = map {$_ == $n ? -1 : $_} @$row;
      if (sum(@$row) == -5) {
        @winner=@$card;
        $winnum = $n;
        $card = undef;
        #last LOOP;
        next CARD;
      }
    }
    for my $cn (0..4) {
      my $s=0;
      for my $rn (0..4) {
        $s++ if ($card->[$rn][$cn] == -1);
      }
      if ($s == 5) {
        @winner=@$card;
        $winnum = $n;
        $card = undef;
        #last LOOP;
        next CARD;
      }
    }
  }
}

my $sum = 0;
for my $row (@winner) {
  for my $n (@$row) {
    $sum+=$n if $n >= 0;
  } 
}
out($sum * $winnum);