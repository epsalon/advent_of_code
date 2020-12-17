#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

sub get_neigh {
  my ($x,$y,$z,$w) = @_;
  my @out;
  for my $xa ($x-1..$x+1) {
    for my $ya ($y-1..$y+1) {
      for my $za ($z-1..$z+1) {
        for my $wa ($w-1..$w+1) {
          next if ($x == $xa && $y == $ya && $z == $za && $w == $wa);
          push @out, "$xa,$ya,$za,$wa";
        }
      }
    }
  }
  return @out;
}

my $res = 0;

my ($minx,$miny,$minz,$minw,$maxx,$maxy,$maxz,$maxw) = (0,0,0,0,0,0,0,0);
my %GRID;

my $y=0;
while(<>) {
  chomp;
  my $x=0;
  for my $c (split('')) {
    $GRID{"$x,$y,0,0"} = 1 if ($c eq '#');
    $x++;
  }
  $maxx=$x;
  $y++;
}

$maxy=$y;

for my $i (0..5) {
  $minx--; $miny--; $minz--; $minw--;
  $maxx++; $maxy++; $maxz++; $maxw++;
  # iteration
  my %next;
  $res = 0;
  for my $x ($minx..$maxx) {
    for my $y ($miny..$maxy) {
      for my $z ($minz..$maxz) {
        for my $w ($minw..$maxw) {
          my $ncount = sum(map {$GRID{$_} || 0} get_neigh($x,$y,$z,$w));
          if ($ncount == 3 || ($ncount == 2 && $GRID{"$x,$y,$z,$w"})) {
            $next{"$x,$y,$z,$w"} = 1;
            $res++;
          }
        }
      }
    }
  }
  %GRID=%next;
}

out $res;