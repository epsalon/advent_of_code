#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq pairs mesh zip shuffle/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use Math::Utils qw(:utility !log10);    # Useful functions

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=0;
$|=1;

my @A;
my %H;
my %E0;
my $sum=0;

#my $grid = Grid::Dense->read();

while (<>) {
  chomp;
  my ($a,$x) = split(': ');
  for my $b (split(' ',$x)) {
    my ($a1,$b1) = sort($a,$b);
    push @{$H{$a1}},$b1;
    push @{$H{$b1}},$a1;
    $E0{"$a1,$b1"}++;
  }
}

sub rep {
  my $uf = shift;
  my $key = shift;
  my @found;
  while (my $next = $uf->{$key}) {
    push @found, $key;
    $key=$next;
  }
  for my $f (@found) {
    $uf->{$f} = $key;
  }
  return $key;
}

sub fastmincut {
  my $vcount = shift;
  my @E = @_;
  my %UF;
  while ($vcount > 2) {
    my ($v1,$v2) = ('','');
    my ($ov1,$ov2);
    while ($v1 eq $v2) {
      my $r = int(rand(@E));
      my $e = $E[$r];
      ($ov1,$ov2) = split(',', $e);
      $v1=rep(\%UF,$ov1);
      $v2=rep(\%UF,$ov2);
      if ($v1 eq $v2) {
        #say "delete $ov1 & $ov2 [map to $v1 = $v2]";
        $E[$r]=$E[-1];
        pop @E;
      }
    }
    #say scalar(%E)." $v1 & $v2 ($ov1 & $ov2)";
    $UF{$v2}=$v1;
    $vcount--;
  }
  return grep {my ($v1,$v2) = split(','); rep(\%UF,$v1) ne rep(\%UF,$v2)} @E;
}

my $i=0;
my @cut;
while (@cut != 3) {
  @cut = fastmincut(scalar(%H),keys(%E0));
}

my @open=(split(',',$cut[0]))[0];

for my $e (@cut) {
  my ($a,$b) = split(',', $e);
  $H{$a} = [grep {$_ ne $b} @{$H{$a}}];
  $H{$b} = [grep {$_ ne $a} @{$H{$b}}];
}

my %closed;
while (@open) {
  my $x = shift @open;
  $closed{$x}++;
  for my $y (@{$H{$x}}) {
    next if $closed{$y};
    push @open,$y;
  }
}

out(scalar(%closed)* (%H - %closed));
