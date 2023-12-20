#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip/;
use POSIX qw/floor ceil Inf log2 log10/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$|=1;

my @A;
my %H;
my $sum=0;

#while (my @R = arr_to_coords('#', read_2d_array())) {

while (<>) {
  chomp;
  last unless $_;

}

out ($sum);
