#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use Math::Utils qw(:utility !log10);    # Useful functions

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my %H;
my $sum=0;

my %G;
#my $grid = Grid::Dense->read();

while (<>) {
  chomp;
  last unless $_;
  my($a,$b) = split('~');
  my @a = split(',', $a);
  my @b = split(',', $b);
  for my $i ($a[0]..$b[0]) {
    for my $j ($a[1]..$b[1]) {
      for my $k ($a[2]..$b[2]) {
        $G{$i,$j,$k} = @A;
      }
    }
  }
  push @A,[$a,$b];
}

sub fall() {
  my $d=1;
  my %fell;
  while ($d) {
    $d=0;
    BLOOP: for my $bi (0..$#A) {
      my $b = $A[$bi];
      next unless $b;
      my @a = split(',' ,$b->[0]);
      my @b = split(',' ,$b->[1]);
      for my $i ($a[0]..$b[0]) {
        for my $j ($a[1]..$b[1]) {
          for my $k ($a[2]..$b[2]) {
            next BLOOP unless $k;
            next BLOOP if defined($G{$i,$j,$k-1}) && $G{$i,$j,$k-1} != $bi;
          }
        }
      }
      $fell{$bi}++;
      for my $i ($a[0]..$b[0]) {
        for my $j ($a[1]..$b[1]) {
          for my $k ($a[2]..$b[2]) {
            delete $G{$i,$j,$k};
          }
        }
      }
      $a[2]--; $b[2]--;
      $A[$bi] = [join(',',@a), join(',',@b)];
      for my $i ($a[0]..$b[0]) {
        for my $j ($a[1]..$b[1]) {
          for my $k ($a[2]..$b[2]) {
            $G{$i,$j,$k}=$bi;
          }
        }
      }
      $d=1;
    }
  }
  return scalar(%fell);
}
fall();

BLOOP2: for my $bi (0..$#A) {
  my $b = $A[$bi];
  my @a = split(',' ,$b->[0]);
  my @b = split(',' ,$b->[1]);
  my %sup;
  for my $i ($a[0]..$b[0]) {
    for my $j ($a[1]..$b[1]) {
      for my $k ($a[2]..$b[2]) {
        next BLOOP2 unless $k;
        if (defined($G{$i,$j,$k-1}) && $G{$i,$j,$k-1} != $bi) {
          $sup{$G{$i,$j,$k-1}}++;
        }
      }
    }
  }
  die unless %sup;
  if (%sup == 1) {
    my ($support) = keys(%sup);
    $H{$support}++;
    say "brick $support cannot be disintegrated because of $bi";
  } else {
    say "brick $bi is supported by ", join(',', keys(%sup));
  }
}

#out(\%G);

out (@A - %H);

for my $bi (0..$#A) {
  dbg($bi);
  my @Atmp = @A;
  my %Gtmp = %G;
  my $b = $A[$bi];
  $A[$bi] = undef;
  my @a = split(',' ,$b->[0]);
  my @b = split(',' ,$b->[1]);
  for my $i ($a[0]..$b[0]) {
    for my $j ($a[1]..$b[1]) {
      for my $k ($a[2]..$b[2]) {
        delete ($G{$i,$j,$k});
      }
    }
  }
  my $fall=fall();
  say "fall($bi)=$fall";
  $sum+=$fall;
  @A=@Atmp;
  %G=%Gtmp;
}

out($sum);