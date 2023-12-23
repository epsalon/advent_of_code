#!/usr/bin/perl -w
use strict;
no warnings 'portable';
no warnings 'recursion';
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
use Math::Utils qw(:utility !log10);    # Useful functions
use Term::ANSIScreen qw(:cursor);

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my %H;
my $sum=0;

my $grid = Grid::Dense->read();

my %HH = qw/< 01 > 0-1 ^ 10 v -10/;

sub chkdir {
  my ($p,$n,$v) = @_;
  return 1 if ($v eq '.');
  my ($px,$py) = split(',',$p);
  my ($nx,$ny) = split(',',$n);
  my ($dx,$dy) = ($nx-$px, $ny-$py);
  return $HH{$v} ne "$dx$dy";
}

sub md {
  my $x = shift;
  return -sum(split(',', $x));
}

my %shortcut;

my $END = "0,1";
my $START = ($grid->rows()-1).",".($grid->cols()-2);

$grid->iterate(sub {
  my ($r,$c,$v) = @_;
  return if ($v eq '#');
  my $rc = "$r,$c";
  my @y = grep {$_->[1] ne '#'} $grid->oneigh($rc);
  return if (@y == 2);
  YYLOOP: for my $yy (@y) {
    my ($prev,$coord)=($rc,$yy->[0]);
    my @n;
    my @path;
    do {
      push @path,$coord;
      @n = grep {$_->[1] ne '#' && $_->[0] ne $prev} $grid->oneigh("$coord");
      $prev = $coord;
      unless (@n) {
        if ($prev ne $END) {
          next YYLOOP;
        }
      } else {
        $coord = $n[0][0];
      }
    } while (@n == 1);
    $shortcut{$rc}{$yy->[0]} = \@path;
  }
});

sub expand {
  my @path = shift;
  EX: while (@_) {
    my $next = shift;
    for my $n (values(%{$shortcut{$path[-1]}})) {
      if ($n->[-1] eq $next) {
        push @path,@$n;
        next EX;
      }
    }
    die "bad path $next";
  }
  return @path;
}

my %best;
my %p;
my @path;
sub scan {
  my ($o,$d) = @_;
  #say "$o,$d";
  $p{$o}++;
  push @path, $o;
  if (!$best{$o} || $best{$o} < $d) {
    $best{$o}=$d;
    if ($o eq $END) {
      locate();
      say $d;
      $grid->print(expand(@path));
    }
  }
  for my $n (values(%{$shortcut{$o}})) {
    my $rc = $n->[-1];
    next if ($p{$rc});
    scan($rc,$d+@$n);
  }
  delete $p{$o};
  pop @path;
}

scan($START,0);

out ($best{$END});
