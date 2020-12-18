#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

sub myeval {
  my $x = shift;
  while ($x=~m{\(}o) {
    my $pre = $`;
    my $post = $';
    my $p=1;
    my $o='';
    for my $c (split('',$post)) {
      $p++ if ($c eq '(');
      $p-- if ($c eq ')');
      last unless $p;
      $o.=$c;
    }
    my $acc = myeval($o);
    $x="$pre$acc".substr($post,length($o)+1);
  }
  my @subs = map {eval($_)} split(/ \* /,$x);
  my $pr = 1;
  for my $s (@subs) {
    $pr *= $s;
  }
  return $pr;
}

my $res = 0;
while(<>) {
  chomp;
  $res += myeval($_);
}

out $res;