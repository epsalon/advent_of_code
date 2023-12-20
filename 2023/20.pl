#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use POSIX qw/floor ceil Inf log2/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

#$AOC::DEBUG_ENABLED=0;
$|=1;

my @A;
my %H;
my %H2;
my $sum=0;
my %M;

#while (my @R = arr_to_coords('#', read_2d_array())) {

while (<>) {
  chomp;
  last unless $_;
  my ($mod,$to) = m{(.)(\S+) -> (.+)$};
  $H{$2} = $1;
  $H2{$2} = [split(', ',$3)];
}

while (my ($k,$v) = each %H2) {
  for my $n (@$v) {
    next unless (($H{$n}//'') eq '&');
    $M{$n}{$k}=0;
  }
}

my @counts;

my %interest = (qw/zp 1 rg 1 sj 1 pp 1/);
my %result;

BIGLOOP: for (my $i=1; ; $i++) {
  my @q=([0,'roadcaster','button']);
  while (@q) {
    my ($sig,$node,$prev) = @{shift @q};
    $counts[$sig]++;
    my $type = $H{$node} or next; #die "node = $node";
    #dbg "$prev -".($sig?'high':'low')."-> $type$node " unless ($type eq '%' && $sig);
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
      my $out = !(all {$_} (values(%{$M{$node}})));
      if (!$out && $interest{$node}) {
        say "$node happy at $i";
        $result{$node} = $i;
        delete $interest{$node};
        unless (%interest) {
          out(product(values(%result)));
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
#dbg(\%H);

