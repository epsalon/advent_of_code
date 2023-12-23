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

sub neigh1 {
  my $coord=shift;
  my @ret = map {
    ($_->[1] ne '#' && chkdir($coord,@$_))?($_->[0]):()
  } $grid->oneigh("$coord");
  return @ret;
}

sub neigh2 {
  my $coord=shift;
  return map {$_->[1] ne '#'?($_->[0]):()} $grid->oneigh("$coord");
}

my $START = "0,1";
my $END = ($grid->rows()-1).",".($grid->cols()-2);

sub shortcut {
  my $neigh = shift;
  my $end = shift;
  my $rc = shift;
  my @y = $neigh->($rc);
  my @shortcut;
  YYLOOP: for my $yy (@y) {
    my ($prev,$coord)=($rc,$yy);
    my @n;
    my @path;
    do {
      push @path,$coord;
      @n = grep {$_ ne $prev} $neigh->($coord);
      $prev = $coord;
      unless (@n) {
        if ($prev ne $end) {
          next YYLOOP;
        }
      } else {
        $coord = $n[0];
      }
    } while (@n == 1);
    push @shortcut, \@path;
  }
  return @shortcut;
}

sub expand {
  my $shortcut = shift;
  my @path = shift;
  EX: while (@_) {
    my $next = shift;
    for my $n ($shortcut->($path[-1])) {
      if ($n->[-1] eq $next) {
        push @path,@$n;
        next EX;
      }
    }
    die "bad path $next";
  }
  return @path;
}

sub find_path {
  my ($neigh,$start,$end) = @_;
  my $shortcut = memoize(sub {
    return shortcut($neigh,$end,@_);
  });
  my %best;
  my %p;
  my @path;
  my @bestpath;
  my $scan;
  $scan = sub {
    my ($o,$d) = @_;
    $p{$o}++;
    push @path, $o;
    if (!$best{$o} || $best{$o} < $d) {
      $best{$o}=$d;
      if ($o eq $end) {
        @bestpath=@path;
      }
    }
    for my $n ($shortcut->($o)) {
      my $rc = $n->[-1];
      next if ($p{$rc});
      $scan->($rc,$d+@$n);
    }
    delete $p{$o};
    pop @path;
  };
  $scan->($start,0);
  return ($best{$end},expand($shortcut,@bestpath));
}

my @p1 = find_path(\&neigh1, $START, $END);
out(shift(@p1));
$grid->print(@p1);
my @p2 = find_path(\&neigh2, $END, $START);
out(shift(@p2));
$grid->print(@p2);

