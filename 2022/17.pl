#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Storable qw(dclone);

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

# Binary conversions
sub bin2dec {
  my $in = shift;
  return oct("0b$in");
}
sub dec2bin {
  my $in = shift;
  return sprintf ("%b", $in);
}

$_=<>;
chomp;
my @A=split('');

# 0 .... 1 ...# 2 ..#. 3 ..##
# 4 .#.. 5 .#.# 6 .##. 7 .###
# 8 #... 9 #..# A #.#. B #.##
# C ##.. D ##.# E ###. F ####

my @SHAPES=
(
  [0x1E],
  [0x08, 0x1C, 0x08],
  [0x1C, 0x04, 0x04],
  [0x10, 0x10, 0x10, 0x10],
  [0x18, 0x18],
);

sub try_shift {
  my ($sh, $pc) = @_;
  my @s = @{$SHAPES[$pc]};
  for my $r (@s) {
    if ((($r << $sh) & 0x7f) >> $sh != $r) {
      return 0;
    }
    $r = $r << $sh;
  }
  return 1;
}

memoize('try_shift');

sub intersect {
  my ($pit,$pc,$f,$sh) = @_;
  for my $i (0..$#$pc) {
    my $pcr = $pc->[$i] << $sh;
    my $ptr = $pit->[$f + $i] || 0;
    return 1 if ($pcr & $ptr);
  }
  return 0;
}

sub unify {
  my ($pit,$pc,$f,$sh) = @_;
  for my $i (0..$#$pc) {
    my $pcr = $pc->[$i] << $sh;
    my $ptr = $pit->[$f + $i] || 0;
    $pit->[$f + $i] = $pcr | $ptr;
  }
}

sub outpit {
  my $pit=shift;
  for my $r (reverse(@$pit)) {
    $r = 0 unless $r;
    my $or = dec2bin($r);
    $or = sprintf("%07d", $or);
    $or =~ tr/01/.#/;
    say ("|$or|");
  }
  say ("+-------+");
}

my @pit;

my $pc=0;
my $pcp=0;
my $i=0;
my $f=0;
my $h=0;
my %memo;
my @s;
my $sh = 0;
for (;;){
  my $ip=0;
  for my $a (@A) {
    $ip++;
    unless ($f) {
      @s = @{$SHAPES[$pc % @SHAPES]};
      $pcp = @pit + 3;
      $f=1;
      $sh=0;
    }
    #my @pitb=@pit;
    #unify(\@pitb,\@s,$pcp,$sh);
    #say "with peice:";
    #outpit(\@pitb);
    my $csh = ($a eq '<' ? 1 : -1);
    $sh+=$csh;
    if (!try_shift($sh,$pc % @SHAPES) || intersect(\@pit,\@s,$pcp,$sh)) {
      $sh-=$csh;
    }
    # Try drop shape
    $pcp--;
    if (intersect(\@pit,\@s,$pcp,$sh) || $pcp < 0) {
      $pcp++;
      unify(\@pit,\@s,$pcp,$sh);
      #outpit(\@pit);
      $pc++;
      while (@pit > 100) {
        shift @pit;
        $h++;
      }
      my $state = join(';',$ip,($pc%@SHAPES),@pit);
      if ($memo{$state} && $pc > 2022) {
        use integer;
        #say "found state $state";
        my ($ppc,$ph) = @{$memo{$state}};
        my ($dpc,$dh) = ($pc-$ppc, $h + 100 - $ph);
        my $rpc = (1000000000000 - $pc);
        my $loops = $rpc / $dpc;
        #say "pc=$pc ppc=$ppc h=$h ph=$ph dpc=$dpc dh=$dh rpc=$rpc loops=$loops";
        $pc+=$loops*$dpc;
        $h+=$loops*$dh;
      }
      $memo{$state}=[$pc,$h+100];
      $f=0;
      if ($pc == 2022) {
        #outpit(\@pit);
        out(scalar(@pit) + $h);
      }
      if ($pc == 1000000000000) {
        #outpit(\@pit);
        out(scalar(@pit)+$h);
        exit;
      }
    }
    #out(\@pit);
  }
}