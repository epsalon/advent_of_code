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

sub inlist {
  my ($el, $list) = @_;
  for my $x (@$list) {
    return 1 if ($x == $el);
  }
  return 0;
}

my $res = 0;

my %SHIFTX = ('e',2,'w',-2,'nw',-1,'ne',1,'sw',-1,'se',+1);
my %SHIFTY = ('e',0,'w',0,'nw',1,'ne',1,'sw',-1,'se',-1);

my %TILES;

sub viz {
  my @grid;
  my ($minx,$miny,$maxx) = (0,0,0);
  for my $k (keys %TILES) {
    $k =~ /^(.+),(.+)$/ or die "$k";
    my ($x,$y) = ($1,$2);
    $maxx = $x if ($x > $maxx);
    $minx = $x if ($x < $minx);
    $miny = $y if ($y < $miny);
  }
  for my $k (keys %TILES) {
    $k =~ /^(.+),(.+)$/ or die "$k";
    my ($x,$y) = ($1-$minx,$2-$miny);
    $grid[$y]->[$x] = 'X';
  }
  my $parity = $miny & 1;
  my $r = $miny;
  for my $row (@grid) {
    printf "%4d ", $r++;
    $parity = !$parity;
    my $p = $parity;
    next unless $row;
    for my $c (0..$maxx - $minx) {
      my $col = $row->[$c];
      print (($col || ($p ? ' ' : '.')));
      $p = !$p;
    }
  } continue {
    print "\n";
  }
}

while (<>) {
  chomp;
  last if /^$/o;
  my $locx = 0;
  my $locy = 0;
  while ($_) {
    m{^(e|se|sw|w|nw|ne)}o;
    my $dir = $1;
    $_ = $';
    $locx += $SHIFTX{$dir};
    $locy += $SHIFTY{$dir};
  }
  my $nv = ($TILES{"$locx,$locy"} = (!$TILES{"$locx,$locy"}));
  $res+= ($nv ? 1 : -1);
}

out ($res);

viz();

for my $gen (0..99) {
  my %neigh;
  for my $t (keys %TILES) {
    next unless $TILES{$t};
    $t =~ /^(.+),(.+)$/ or die "$t";
    my ($x,$y) = ($1,$2);
    for my $d (keys %SHIFTX) {
      my $sx = $x + $SHIFTX{$d};
      my $sy = $y + $SHIFTY{$d};
      $neigh{"$sx,$sy"}++;
    }
  }
  my %ntiles;
  while (my ($k,$v) = each %neigh) {
    if (($TILES{$k} && ($v == 1)) || ($v == 2)) {
      $ntiles{$k} = 1;
    }
  }
  %TILES = %ntiles;
  out scalar(%TILES);
}

viz();