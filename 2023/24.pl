#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use feature 'say';
use IPC::Open2;

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my $sum=0;

while (<>) {
  chomp;
  last unless $_;
  my @a = smart_split($_);
  push @A,[@a];
}

my ($tmin,$tmax) = $A[0][0] > 10000 ? (200000000000000, 400000000000000) : (7,27);

for my $i (0..$#A-1) {
  for my $j ($i..$#A) {
    my @a=@{$A[$i]};
    my @b=@{$A[$j]};
    my ($A, $B, $C ,$D, $E, $F, $G, $H) = ($a[1], $a[0], $a[4], $a[3],$b[1], $b[0], $b[4], $b[3]);
    my $divisor = ($D * $G - $C * $H);
    next unless $divisor;
    my $X = ($A * $D * $H - $B *$C * $H - $D * $E * $H + $D * $F * $G)/$divisor;
    my $Y = $A + ($X-$B)*$C/$D;
    next if ($X-$a[0])/$a[3] < 0;
    next if ($X-$b[0])/$b[3] < 0;
    $sum++ if ($X>=$tmin && $X <= $tmax && $Y >= $tmin && $Y <= $tmax );
  }
}

out ($sum);

# Part 2

my $pid = open2(my $zin, my $zout, "z3", "-in") or die;
for my $c (qw/x y z vx vy vz/) {
  say $zout "(declare-const $c Real)"
}

my $i=1;
for my $a (@A) {
  my ($x,$y,$z,$vx,$vy,$vz) = @$a;
  say $zout "(declare-const t$i Real)";
  say $zout "(assert (= (+ x (* vx t$i)) (+ $x (* $vx t$i))))";
  say $zout "(assert (= (+ y (* vy t$i)) (+ $y (* $vy t$i))))";
  say $zout "(assert (= (+ z (* vz t$i)) (+ $z (* $vz t$i))))";
  $i++;
}

say $zout "(declare-const answer Real)";
say $zout "(assert (= answer (+ x y z)))";
say $zout "(check-sat)";
say $zout "(get-value (answer))";
close($zout);

waitpid($pid, 0);

while (<$zin>) {
  print;
  next unless /answer/;
  my ($ans) = m{\s+(\d+)\.}o or die;
  out($ans);
  last;
}
close($zin);
