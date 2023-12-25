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

my $res = 0;
my %ING;
my %ALL;
while(<>) {
  chomp;
  m{^([\w\s]+)\(contains ([\w\s,]+)\)$}o or die;
  my @ilist = split(' ', $1);
  for my $i (@ilist) {
    $ING{$i}++;
  }
  my @alist = split(/,\s+/, $2);
  for my $a (@alist) {
    my %ihash = map {$_ => 1} @ilist;
    unless ($ALL{$a}) {
      $ALL{$a} = \%ihash;
    } else {
      foreach (keys %{$ALL{$a}}){
        delete $ALL{$a}{$_} unless $ihash{$_};
      }
    }
  }
}

print Dumper(\%ALL);

for my $i (keys %ING) {
  my $good = 1;
  for my $a (values %ALL) {
    if ($a->{$i}) {
      $good = 0;
      last;
    }
  }
  $res+= $ING{$i} if $good;
}

out ($res);

my %RES;

while (%ALL) {
  my ($i, $a); 
  while (my ($k, $v) = each %ALL) {
    if (%$v == 1) {
      ($i) = keys %$v;
      $a = $k;
      last;
    }
  }
  $RES{$a} = $i;
  delete $ALL{$a};
  for my $data (values %ALL) {
    delete $data->{$i};
  }
}

print Dumper(\%RES);

my @alist = map {$RES{$_}} (sort(keys %RES));

$res = join(',', @alist);

out $res;
