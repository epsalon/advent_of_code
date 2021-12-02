#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
no warnings;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my @MEM;  # [addr, float, val]

my $mask0;
my $mask1;
my $maskf;
my @XLIST;

sub intersect {
  my ($a1,$f1,$a2,$f2) = @_;
  return () unless (($a1 & ~$f2) == ($a2 & ~$f1));
  return ($a1 | $a2, $f1 & $f2);
}

sub cover {
  my ($f) = @_;
  my $out = 1;
  while ($f) {
    $f &= ($f - 1);
    $out <<= 1;
  }
  return $out;
}

while (<>) {
  print;
  say "MEM SIZE = ",scalar(@MEM);
  chomp;
  if (m{^mask = ([01X]+)$}o) {
    my $mask = $1;
    my $m1 = $mask;
    $m1 =~ tr/X/0/;
    $mask1 = oct("0b$m1");
    my $m0 = $mask;
    $m0 =~ tr/0X/10/;
    $mask0 = oct("0b$m0");
    my @mask = split('', $mask);
    my $mf = $mask;
    $mf =~ tr/1X/01/;
    $maskf = oct("0b$mf");
  } elsif (m{^mem\[(\d+)\] = (\d+)$}o) {
    my ($addr, $val) = ($1,$2);
    $addr |= $mask1;
    $addr &= $mask0;
    my @new = ([$addr, $maskf, $val]);
    for my $mem (@MEM) {
      my ($ma, $mf, $mv) = @$mem;
      my ($ia, $if) = intersect($addr, $maskf, $ma, $mf);
      if (defined($ia)) {
        push @new, [$ia, $if, -$mv];
      }
    }
    push @MEM, @new;
  }
}

say scalar(@MEM);

my $sum = 0;
for my $mem (@MEM) {
  my ($ma, $mf, $mv) = @$mem;
  $sum += $mv * cover($mf);
}

out $sum;