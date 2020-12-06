#!/usr/bin/perl -w
use strict;

my $in;
while (<>) {
  chomp;
  $in.=$_;
}

sub run {
  my @PROG = @_;
  my $pc = 0;
  while ($PROG[$pc] != 99) {
    my $op = $PROG[$pc];
    if ($op == 1) {
      $PROG[$PROG[$pc+3]] = $PROG[$PROG[$pc+1]] + $PROG[$PROG[$pc+2]]; 
    }
    if ($op == 2) {
      $PROG[$PROG[$pc+3]] = $PROG[$PROG[$pc+1]] * $PROG[$PROG[$pc+2]]; 
    }
    $pc += 4;
  }
  return $PROG[0];
}

my @IN = split(/,/, $in);

for my $noun (0..99) {
  $IN[1] = $noun;
  for my $verb (0..99) {
    $IN[2] = $verb;
    my $res = run(@IN);
    if ($res == 19690720) {
      print $noun * 100 + $verb, "\n";
    }
  }
}
