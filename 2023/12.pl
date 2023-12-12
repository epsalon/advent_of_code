#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
# use POSIX;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections("./submit.py $out");
    print "$out\n";
  }
}

sub solve {
  no warnings 'recursion';
  my $str = shift;
  my $sum = 0;

  #say "SOLVE($str,".join(',',@v).")";

  if (!@_) {
    my $ret = $str =~ /^[\.\?]*$/o;
    #say "no more v - returning $ret";
    return $ret;
  }
  if ($str =~ /^[\.\?](.*)$/o) {
    #say "assuming .";
    $sum += solve($1,@_);
  }
  my $v0 = shift;
  if ($str =~ /^[\#\?]{$v0}(?:[\.\?](.*))?$/) {
    #say "placing series of #";
    $sum += solve($1||'',@_);
  }
  #say "returning $sum";
  return $sum;
}

memoize('solve');
my $sumA = 0;
my $sumB = 0;

while (<>) {
  chomp;
  last unless $_;
  m{([#\?\.]+) ([\d,]+)}o;
  my $r = $1;
  my @v = split(',',$2);
  $sumA += solve($r,@v);
  $r = join('?', ($r) x 5);
  @v = (@v) x 5;
  $sumB += solve($r,@v);
}

out ($sumA);
out ($sumB);
