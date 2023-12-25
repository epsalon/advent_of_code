#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my %OPTIONS;
my %RULES;
while(<>) {
  chomp;
  last if /^$/;
  m{^([\w\s]+): (\d+)-(\d+) or (\d+)-(\d+)$};
  $RULES{$1} = [[$2,$3],[$4,$5]];
  $OPTIONS{$1} = {};
}

scalar(<>);
my $ytkt = scalar(<>);
scalar(<>);
scalar(<>);


while (<>) {
  chomp;
  my @tick = split(/,/, $_);
  for my $i (0..$#tick) {
    my $v = $tick[$i];
    my $good = 0;
    for my $r (values %RULES) {
      for my $rl (@$r) {
        my ($min,$max) = @$rl;
        $good=1 if ($v >= $min && $v <= $max);
      }
    }
    if ($good) {
      while (my ($k,$r) = each %RULES) {
        my $goodx = 0;
        for my $rl (@$r) {
          my ($min,$max) = @$rl;
          $goodx=1 if ($v >= $min && $v <= $max);
        }
        unless ($goodx) {
          $OPTIONS{$k}{$i}=-1; # not possible
          say "opt{$k}[$i]";
        }
      }
    }
  }
}

chomp $ytkt;
my @ytkt = split(/,/, $ytkt);

print Dumper(\@ytkt);
print Dumper(\%OPTIONS);

my @OPTS;
while (my ($k,$v) = each %OPTIONS) {
  push @OPTS, [scalar(%$v), $v, $k];
}

@OPTS = sort {$b->[0] <=> $a->[0]} @OPTS;
print Dumper(\@OPTS);

my @flds;
for my $o (@OPTS) {
  my ($c, $v, $k) = @$o;
  for my $i (0..$#ytkt) {
    next if $flds[$i];
    unless ($v->{$i}) {
      $flds[$i] = $k;
    }
  }
}

print Dumper(\@flds);

my $product = 1;
for my $i (0..$#ytkt) {
  my $v = $ytkt[$i];
  my $f = $flds[$i];
  next unless $f =~ /^departure/;
  $product *= $v;
}

out $product;
