#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Math::Trig ':pi';

my ($dirx, $diry) = (10,-1);
my ($posx, $posy) = (0,0);

my %XDIRS = qw/N 0 S 0 E 1 W -1/;
my %YDIRS = qw/N -1 S 1 E 0 W 0/;

while (<>) {
  print;
  chomp;
  /^([NEWSLRF])(\d+)$/ or die;
  my ($cmd,$val) = ($1,$2);
  if ($cmd eq 'F') {
    $posx+=$dirx * $val;
    $posy+=$diry * $val;
  } elsif (defined($XDIRS{$cmd})) {
    $dirx+=$XDIRS{$cmd} * $val;
    $diry+=$YDIRS{$cmd} * $val;
  } else {
    if ($cmd eq 'R') {
      $val = -$val;
    }
    my $rad = ($val * pi)/180;
    
    ($dirx, $diry) = ($dirx*cos($rad) + $diry*sin($rad), $diry*cos($rad) - $dirx*sin($rad));
    print "$dirx $diry\n";
  }
}

print abs($posx) + abs($posy),"\n";
