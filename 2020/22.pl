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

sub rcombat {
  my ($ad, $bd, $sh) = @_;
  my %SH = %$sh;
  my @A = @$ad;
  my @B = @$bd;
  while (@A && @B) {
    my $id = join(',', @A).";".join(',', @B);
    if ($SH{$id}) {
      #say "   SEEN $id A WINS";
      return ($ad, []);
    }
    $SH{$id} = 1;
    my ($a, $b) = (shift (@A), shift(@B));
    if (@A < $a || @B < $b) {
      if ($a > $b) {
        push @A, $a, $b;
      } else {
        push @B, $b, $a;
      }
    } else {
      my @ax = @A[0..$a-1];
      my @bx = @B[0..$b-1];
      my ($aw) = rcombat(\@ax, \@bx, \%SH);
      my $wl = @$aw ? \@A : \@B;
      my $wc = @$aw ? $a : $b;
      my $lc = @$aw ? $b : $a;
      push @$wl, $wc, $lc;
    }
  }
  return (\@A, \@B);
}

my (@A, @B);

scalar(<>);
while(<>) {
  chomp;
  last if /^$/;
  push @A, $_;
}

scalar(<>);
while(<>) {
  chomp;
  last if /^$/;
  push @B, $_;
}

my ($ra, $rb) = (rcombat(\@A, \@B, {}));

my @R = (@$ra, @$rb);

my $res=0;
my $i=1;
while (@R) {
  $res += pop(@R) * ($i++);
}

out ($res);
exit;

while (@A && @B) {
  my ($a, $b) = (shift (@A), shift(@B));
  if ($a > $b) {
    push @A, $a, $b;
  } else {
    push @B, $b, $a;
  }
}
