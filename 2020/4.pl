#!/usr/bin/perl -w
use strict;

my @FIELDS = qw/byr iyr eyr hgt hcl ecl pid/;

my @YEARS = (['byr', 1920, 2002], ['iyr', 2010, 2020], ['eyr', 2020, 2030]);

my %HEIGHTS = ('in', [59,76], 'cm', [150,193]);

my %EYES = qw/amb 1 blu 1 brn 1 gry 1 grn 1 hzl 1 oth 1/;

my %PASS;

my $ok = 0;

while (<>) {
  print;
  chomp;
  while (m{(\w\w\w):(\S+)\s*}go) {
    $PASS{$1} = $2;
  }
  if (m{^$}) {
    for my $f (@YEARS) {
      if (!$PASS{$f->[0]} || $PASS{$f->[0]} !~ /^\d\d\d\d$/o || $PASS{$f->[0]} < $f->[1] || $PASS{$f->[0]} > $f->[2]) {
        print "bad ". $f->[0] . "\n";
        goto BAD;
      }
    }
    if (($PASS{hgt} || '') !~ /^(\d+)(cm|in)$/o) {
      print "bad hgt\n";
      goto BAD;
    }
    if ($1 < $HEIGHTS{$2}[0] || $1 > $HEIGHTS{$2}[1]) {
      print "bad hgt val\n";
      goto BAD;
    }
    if (($PASS{hcl} || '') !~ /^#[0-9a-f]{6}$/) {
      print "bad hcl\n";
      goto BAD;
    }
    unless ($EYES{$PASS{ecl} || ''}) {
      print "bad ecl\n";
      goto BAD;
    }
    if (($PASS{pid} || '') !~ /^[0-9]{9}$/) {
      print "bad pid\n";
      goto BAD;
    }
    $ok++;
    BAD:
    %PASS = ();
  }
}

print "$ok\n";