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

my @REV;

for my $i (0..$#PROG) {
  my $l = $PROG[$i];
  $l =~ m{^(\w+)\s+([-+]\d+)$};
  my ($opc, $arg) = ($1, $2);
  my $target = $i + 1;
  if ($opc eq "jmp") {
    $target = $i + $arg;
  }
  push @{$REV[$target]}, $i;
}

my %endzone;
my @q = ($#PROG + 1);
while (@q) {
  my $i = shift @q;
  $endzone{$i}++;
  for my $r (@{$REV[$i]}) {
    if (!$endzone{$r}) {
      push @q, $r;
    }
  }
}

my %SEEN;
my $pc = 0;
my $acc = 0;

while (!$SEEN{$pc}) {
  $SEEN{$pc}++;
  if ($pc > $#PROG) {
    print "$acc\n";
    exit;
  }
  my $inst = $PROG[$pc];
  $inst =~ m{^(\w+)\s+([-+]\d+)$};
  my $alt = $pc + 1;
  my ($opc, $arg) = ($1, $2);
  if ($opc eq "acc") {
    $acc += $arg;
  } elsif ($opc eq "jmp") {
    $pc += $arg - 1;
  } elsif ($opc eq "nop") {
    $alt = $pc + $arg;
  }
  $pc++;
  if (!$endzone{$pc} && $endzone{$alt}) {
    print "Set PC from $pc to $alt\n";
    $pc = $alt;
  }
}
