#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use feature 'say';
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Utils qw(:utility);    # Useful functions

BEGIN {push @INC, "../lib";}
use AOC ':all';

$AOC::DEBUG_ENABLED=0;
$|=1;

my @A;
my %H;
my %H2;
my $sum=0;
my %M;
my %interest;
my %result;

while (<>) {
  chomp;
  last unless $_;
  my ($type,$mod,$to) = m{(.)(\S+) -> (.+)$};
  $H{$mod} = $type;
  $H2{$mod} = [split(', ',$to)];
  $interest{$mod}++ if ($type eq '&')
}

while (my ($k,$v) = each %H2) {
  for my $n (@$v) {
    next unless (($H{$n}//'') eq '&');
    $M{$n}{$k}=0;
  }
}

my @counts;


BIGLOOP: for (my $i=1; ; $i++) {
  my @q=([0,'roadcaster','button']);
  while (@q) {
    my ($sig,$node,$prev) = @{shift @q};
    $counts[$sig]++;
    my $type = $H{$node} or next; #die "node = $node";
    dbg "$prev -".($sig?'high':'low')."-> $type$node " unless ($type eq '%' && $sig);
    if ($type eq 'b') {
      for my $n (@{$H2{$node}}) {
        push @q, [$sig,$n, $node];
      }
    } elsif ($type eq '%') {
      next if $sig;
      $M{$node}=!$M{$node};
      for my $n (@{$H2{$node}}) {
        push @q, [$M{$node},$n,$node];
      }
    } elsif ($type eq '&') {
      $M{$node}{$prev} = $sig;
      my $out = (notall {$_} (values(%{$M{$node}})));
      if (!$out && $interest{$node}) {
        dbg("$node happy at $i");
        $result{$node} = $i;
        delete $interest{$node};
        if (%interest == 1 && ($i > 1000)) {
          out(lcm(values(%result)));
          last BIGLOOP;
        }
      }
      for my $n (@{$H2{$node}}) {
        push @q, [$out,$n,$node];
      }
    }
  }
  out (product(@counts)) if ($i == 1000);
}

