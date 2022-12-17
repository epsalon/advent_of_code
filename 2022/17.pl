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

sub get_row {
  my ($pit,$r) = @_;
  if ($r > $#$pit) {
    return 0;
  }
  return $pit->[$r] || 0;
}

sub try_shift {
  my ($sh, @s) = @_;
  for my $r (@s) {
    if (($r & 0x01 && $sh < 0) || ($r & 0x40 && $sh > 0)) {
      # Can't shift
      return ();
    }
    $r = $r << $sh;
  }
  return @s;
}

memoize('try_shift');

sub intersect {
  my ($pit,$pc,$f) = @_;
  for my $i (0..$#$pc) {
    my $pcr = $pc->[$i];
    my $ptr = get_row($pit, $f + $i);
    return 1 if ($pcr & $ptr);
  }
  return 0;
}

sub unify {
  my ($pit,$pc,$f) = @_;
  for my $i (0..$#$pc) {
    my $pcr = $pc->[$i];
    my $ptr = get_row($pit, $f + $i);
    my $newr = $pcr | $ptr;
    $pit->[$f + $i] = $newr;
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
for (;;){
  my $ip=0;
  for my $a (@A) {
    $ip++;
    unless ($f) {
      @s = @{$SHAPES[$pc % @SHAPES]};
      $pcp = @pit + 3;
      $f=1;
    }
    #my @pitb=@pit;
    #unify(\@pitb,\@s,$pcp);
    #say "with peice:";
    #outpit(\@pitb);
    my $sh = ($a eq '<' ? 1 : -1);
    if (my @sb = try_shift($sh,@s)) {
      if (!intersect(\@pit,\@sb,$pcp)) {
        @s=@sb;
      }
    }
    # Try drop shape
    $pcp--;
    if (intersect(\@pit,\@s,$pcp) || $pcp < 0) {
      $pcp++;
      unify(\@pit,\@s,$pcp);
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