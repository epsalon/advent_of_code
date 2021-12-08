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

my $o;
my $o1;
my @LOOKUP = qw/x e x x g a b d c f/;
my @SSEG=qw/abcefg cf acdeg acdfg bcdf abdfg abdefg acf abcdefg abcdfg/;
my %RSEG;
{
  my $i=0;
  for my $s (@SSEG) {
    $RSEG{$s} = $i++;
  }
}

while (<>) {
    chomp;
    my @l = split(/ \| /);
    my @a = split(' ', $l[0]);
    my @od = split(' ', $l[1]);
    my %four;
    my %count;
    for my $a (@a) {
      my $is_four = (length($a) == 4);
      for my $c (split('', $a)) {
        $count{$c}++;
        $four{$c}++ if $is_four;
      }
    }
    my $v;
    for my $x (@od) {
      my $c;
      $c = join('', sort {$a cmp $b} (map {
        $LOOKUP[$count{$_} - 3 * !$four{$_}]
      }  split('', $x)));
      $v.=$RSEG{$c};
      $o1++ if ($RSEG{$c} =~ /[1478]/);
    }
    $o+=$v;
}

out $o1;
out $o;