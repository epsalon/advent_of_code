#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my @PROG;

while (<>) {
  print;
  chomp;
  push @PROG, $_;
}

sub run {
  my @PROG = @_;
  my %SEEN;
  my $pc = 0;
  my $acc = 0;

  while (!$SEEN{$pc}) {
    $SEEN{$pc}++;
    if ($pc > $#PROG) {
      return $acc;
    }
    my $inst = $PROG[$pc];
    $inst =~ m{^(\w+)\s+([-+]\d+)$};
    my ($opc, $arg) = ($1, $2);
    if ($opc eq "acc") {
      $acc += $arg;
    } elsif ($opc eq "jmp") {
      $pc += $arg - 1;
    }
    $pc++;
  }
  return "fail";
}

for my $i (0..$#PROG) {
  next if ($PROG[$i] =~ /acc/);
  my @tmp = @PROG;
  $_ = $PROG[$i];
  s/jmp/tmp/;
  s/nop/jmp/;
  s/tmp/nop/;
  $tmp[$i] = $_;
  my $res = run(@tmp);
  if ($res ne 'fail') {
    print "$res\n";
  }
}

