#!/usr/bin/perl -w
use strict;

my ($min, $max, $sum) = (1025, -1, 0);

my $ok = 0;

while (<>) {
  chomp;
  unless (m{^(\d+)-(\d+)\s+(.):\s+(.+)$}go) {
    print "ERR $_\n";
    next;
  }
  my ($min, $max, $ch, $str) = ($1,$2,$3,$4);
  #my $count = () = $str =~ /$ch/g;
  #if ($count >= $min && $count <= $max) {
  #  $ok++;
  #} else {
  #  print "$_ \t | $min $max $count\n";
  #}
  my $ch1_ok = substr($str,$min-1,1) eq $ch;
  my $ch2_ok = substr($str,$max-1,1) eq $ch;
  if ($ch1_ok xor $ch2_ok) {
    $ok++;
  }
}

print "$ok\n";