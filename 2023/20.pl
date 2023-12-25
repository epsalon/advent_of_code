#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use feature 'say';
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Utils qw(:utility);    # Useful functions

BEGIN {push @INC, "../lib";}
use AOC ':all';

$AOC::DEBUG_ENABLED=1;
$|=1;

my %types;
my %outputs;
my %memory;
my %interest;
my %result;

while (<>) {
  chomp;
  last unless $_;
  my ($type,$mod,$to) = m{(.)(\S+) -> (.+)$};
  $types{$mod} = $type;
  $outputs{$mod} = [split(', ',$to)];
  $interest{$mod}++ if ($type eq '&')
}

while (my ($k,$v) = each %outputs) {
  for my $n (@$v) {
    next unless (($types{$n}//'') eq '&');
    $memory{$n}{$k}=0;
  }
}

my @counts;


BIGLOOP: for (my $i=1; ; $i++) {
  dbg "iteration $i";
  my @q=([0,'roadcaster','button']);
  while (@q) {
    my ($sig,$node,$prev) = @{shift @q};
    $counts[$sig]++;
    my $type = $types{$node} // '';
    dbg (($types{$prev}//'')."$prev -".($sig?'high':'low')."-> $type$node");
    next unless $type;
    if ($type eq '%') {
      next if $sig;
      $sig=$memory{$node}=!$memory{$node};
    } elsif ($type eq '&') {
      $memory{$node}{$prev} = $sig;
      $sig = (notall {$_} (values(%{$memory{$node}})));
      if ($sig && $interest{$node}) {
        dbg("$node happy at $i");
        $result{$node} = $i;
        delete $interest{$node};
        if (!%interest && ($i > 1000)) {
          out(lcm(values(%result)));
          last BIGLOOP;
        }
      }
    }
    for my $n (@{$outputs{$node}}) {
      push @q, [$sig, $n, $node];
    }
  }
  if ($i == 1000) {
    dbg(\@counts);
    out(product(@counts));
  }
}
