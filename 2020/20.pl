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

my %TILES;
my %EDGES;

my $res = 1;

sub rotate {
  my @T = @_;
  my @out;
  for my $i (0..$#T) {
    for my $j (0..$#T) {
      $out[$j][$#T-$i] = substr($T[$i],$j,1);
    }
  }
  return map {join('', @$_)} @out;
}

sub rotn {
  my $t = shift;
  my $n = shift;
  my @T = @$t;
  for my $i (1..$n) {
    @T = rotate(@T);
  }
  return @T;
}

sub flip {
  my @T = @_;
  my @out;
  for my $i (0..$#T) {
    for my $j (0..$#T) {
      $out[$#T-$i][$j] = substr($T[$i],$j,1);
    }
  }
  return map {join('', @$_)} @out;
}

while(<>) {
  chomp;
  m{^Tile (\d+):$} or die;
  my $tn = $1;
  my @T;
  while (<>) {
    chomp;
    last if /^$/;
    push @T, $_;
  }
  my @T1 = rotate(@T);
  my @T2 = rotate(@T1);
  my @T3 = rotate(@T2);
  my @T4 = flip(@T);
  my @T5 = flip(@T1);
  my @T6 = flip(@T2);
  my @T7 = flip(@T3);
  $TILES{$tn} = [\@T, \@T1, \@T2, \@T3, \@T4, \@T5, \@T6, \@T7];
}

my %CORNERS;

my $corner;

for my $k (keys %TILES) {
  my $v = $TILES{$k};
  my @sides = 
    ($v->[0]->[0], $v->[0]->[-1], $v->[1]->[0], $v->[1]->[-1]);
  my $unmatched = 0;
  my @ms;
  for my $s (@sides) {
    #say "------ $s";
    my $match = 0;
    TLOOP: for my $ok (keys %TILES) {
      next if ($ok == $k);
      my $ov = $TILES{$ok};
      for my $r (@$ov) {
        #say "  $ok ", $r->[0];
        if ($r->[0] eq $s) {
          $match = 1;
          #say "  MATCH!";
          last TLOOP;
        }
      }
    }
    push @ms, $match;
    $unmatched++ unless $match;
  }
  if ($unmatched == 2) {
    $res *= $k;
    $CORNERS{$k}++;
    if ($ms[1] && $ms[3]) {
      $corner = $k;
    }
  }
}

out ($res);

my $SIZE = int(sqrt(%TILES));

my @GRID = ([$TILES{$corner}->[0]]);

delete $TILES{$corner};

sub fillrow {
  my $row = shift;
  while (@$row < $SIZE) {
    #say scalar(@$row), $SIZE;
    my $t = $row->[-1];
    my @rt = rotate(@$t);
    my $s = $rt[-1];
    TLOOP: for my $ok (keys %TILES) {
      my $ov = $TILES{$ok};
      for my $r (@$ov) {
        if ($r->[0] eq $s) {
          my @rtr = rotn($r,3);
          push @$row, \@rtr;
          delete $TILES{$ok};
          last TLOOP;
        }
      }
    }
  }
}

sub startrow {
  my $lastrowfirst = shift;
  my $s = $lastrowfirst->[-1];
  TLOOP: for my $ok (keys %TILES) {
    my $ov = $TILES{$ok};
    for my $r (@$ov) {
      if ($r->[0] eq $s) {
        delete $TILES{$ok};
        return $r;
      }
    }
  }
}

fillrow($GRID[0]);
while (@GRID < $SIZE) {
  push @GRID, [ startrow($GRID[-1][0]) ];
  fillrow($GRID[-1]);
}

## CLEAN GRID
my @CG;

my $tsz = $#{$GRID[0][0]};

for my $row (@GRID) {
  for my $trow (1..$tsz-1) {
    my $outrow;
    for my $col (@$row) {
      my $irow = $col->[$trow];
      $outrow .= substr($irow,1,-1);
    }
    push @CG, $outrow;
  }
}

my @SEAMONSTER = map {[split('')]} (
  '                  # ',
  '#    ##    ##    ###',
  ' #  #  #  #  #  #   ');

sub findsm {
  my $smcount = 0;
  my @TG = map {[split('')]} @CG;
  for my $smlr (0..$#TG-$#SEAMONSTER) {
    for my $smlc (0..$#TG-$#{$SEAMONSTER[0]}) {
      my $found = 1;
      CHECKMONSTER: for my $dr (0..$#SEAMONSTER) {
        my $smr = $SEAMONSTER[$dr];
        for my $dc (0..$#$smr) {
          next if ($smr->[$dc] eq ' ');
          if ($TG[$smlr + $dr][$smlc + $dc] eq '.') {
            $found = 0;
            last CHECKMONSTER;
          }
        }
      }
      if ($found) {
        $smcount++;
        for my $dr (0..$#SEAMONSTER) {
          my $smr = $SEAMONSTER[$dr];
          for my $dc (0..$#$smr) {
            next if ($smr->[$dc] eq ' ');
            $TG[$smlr + $dr][$smlc + $dc] = 'O';
          }
        }
      }
    }
  }
  return 0 unless $smcount;
  @CG = map {join('', @$_)} @TG;
  my $hcount = 0;
  for my $r (@TG) {
    for my $c (@$r) {
      $hcount++ if ($c eq '#');
    }
  }
  return $hcount;
}

my $hcount;

for (;;) {
  last if $hcount=findsm();
  @CG = flip(@CG);
  last if $hcount=findsm();
  @CG = flip(@CG);
  @CG = rotate(@CG);
}

print Dumper(\@CG);

out($hcount);