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

my @SHAPES=
(
  [0b0011110],

  [0b0001000,
   0b0011100,
   0b0001000],

  [0b0011100,
   0b0000100,
   0b0000100],

  [0b0010000,
   0b0010000,
   0b0010000,
   0b0010000],

  [0b0011000,
   0b0011000],
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

sub run_sim {
  my ($input,$CUTOFF,@LIMITS) = @_;
  my @A = @$input;
  my @pit;

  my $pc=0;
  my $pcp=0;
  my $f=0;
  my $h=0;
  my %memo;
  my @s;
  my $sh = 0;
  my $ip=0;
  my @res;
  while (@LIMITS) {
    my $a = $A[$ip++];
    $ip = 0 if $ip == @A;
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
      return () if ($pcp < 0 && $h);
      $pcp++;
      unify(\@pit,\@s,$pcp,$sh);
      #outpit(\@pit);
      $pc++;
      while (@pit > $CUTOFF) {
        shift @pit;
        $h++;
      }
      my $state = join(';',$ip,($pc%@SHAPES),@pit);
      if ($memo{$state}) {
        use integer;
        #say "found state $state";
        my ($ppc,$ph) = @{$memo{$state}};
        my ($dpc,$dh) = ($pc-$ppc, $h - $ph);
        my $rpc = ($LIMITS[0] - $pc);
        my $loops = $rpc / $dpc;
        if ($loops) {
          say "state=$state";
          say "pc=$pc ppc=$ppc h=$h ph=$ph dpc=$dpc dh=$dh rpc=$rpc loops=$loops";
        }
        $pc+=$loops*$dpc;
        $h+=$loops*$dh;
      }
      $memo{$state}=[$pc,$h];
      $f=0;
      if ($pc == $LIMITS[0]) {
        #outpit(\@pit);
        shift @LIMITS;
        push(@res, scalar(@pit) + $h);
      }
    #out(\@pit);
    }
  }
  return @res;
}

$_=<>;
chomp;
my @A=split('');

my @LIMITS = (2022, 1000000000000);

my $cutoff = 8;

my @res;

for (; !@res; $cutoff*=2) {
  @res = run_sim(\@A, $cutoff, @LIMITS);
}

say "final cutoff=$cutoff";

for my $r (@res) {
  out($r);
}
