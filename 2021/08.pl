#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum/;
use Math::Cartesian::Product;
use Math::Complex;

sub out {
  my $out = shift;
  Clipboard->copy_to_all_selections($out);
  print "$out\n";
}

my @A;

my @L;

my $o=0;

my @SSEG=qw/abcefg cf acdeg acdfg bcdf abdfg abdefg acf abcdefg abcdfg/;

# 1,4,7,8

# a = 7 but not 1,4
# b + d = 4 but not 1, 7
## b count = 6, d count = 7
# c + f = 1 & 4 & 7
## c count = 8, f count = 9
# e + g = not 1,4,7
## e count = 4, g count = 7

sub to_set {
  my $x = shift;
  my %h;
  for my $c (split('', $x)) {
    $h{$c}++;
  }
  return \%h;
}

my %RSEG;
my $i=0;
for my $s (@SSEG) {
  $RSEG{$s} = $i++;
}

while (<>) {
    print;
    chomp;
    my @l = split(/ \| /);
    my @a = split(' ', $l[0]);
    @l = split(' ', $l[1]);
    my ($one, $seven, $four);
    my %count;
    for my $a (@a) {
      if (length($a) == 2) {
        $one = to_set($a);
      }
      if (length($a) == 3) {
        $seven = to_set($a);
      }
      if (length($a) == 4) {
        $four = to_set($a);
      }
      for my $c (split('', $a)) {
        $count{$c}++;
      }
    }
    my %map;
    for my $a (qw/a b c d e f g/) {
      if ($seven->{$a} && !$four->{$a} && !$one->{$a}) {
        $map{$a} = 'a';
      } elsif ($four->{$a} && !$one->{$a} && !$seven->{$a}) {
        if ($count{$a} == 6) {
          $map{$a} = 'b';
        } elsif ($count{$a} == 7) {
          $map{$a} = 'd';
        }
      } elsif ($four->{$a} && $one->{$a} && $seven->{$a}) {
        if ($count{$a} == 8) {
          $map{$a} = 'c';
        } elsif ($count{$a} == 9) {
          $map{$a} = 'f';
        }
      } elsif (!$four->{$a} && !$one->{$a} && !$seven->{$a}) {
        if ($count{$a} == 4) {
          $map{$a} = 'e';
        } elsif ($count{$a} == 7) {
          $map{$a} = 'g';
        }
      }
      die "$a" unless $map{$a};
    }
    my $v;
    for my $x (@l) {
      my $c;
      $c = join('', sort {$a cmp $b} (map {$map{$_}}  split('', $x)));
      $v.=$RSEG{$c};
    }
    print "ans=$v\n";
    $o+=$v;
}


out $o;