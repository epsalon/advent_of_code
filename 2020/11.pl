#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use bigint;

my @A;

while (<>) {
  #print;
  chomp;
  push @A, $_;
}

# my @sorted = sort {$a <=> $b} @A;

my @neigh = ([-1,-1], [-1,0], [-1,1], [0,-1], [0, 1], [1,-1], [1,0], [1,1]);

my @m = map {my @r = split(//); \@r} @A;

my $ch =1;
while ($ch) {
  $ch = 0;
  my @new;
  for my $r (0.. $#m) {
    my $rv = $m[$r];
    my @rvc = @$rv;
    push @new, \@rvc;
    for my $c (0..$#$rv) {
      my $cv = $rv->[$c];
      #print "RC $r $c $cv\n";
      next if ($cv eq '.');
      my $cnt = 0;
      for my $n (@neigh) {
        my ($rd, $cd) = @$n;
        my $rn = $r + $rd;
        next if ($rn < 0 || $rn > $#m);
        my $cn = $c + $cd;
        next if ($cn < 0 || $cn > $#$rv);
        #print "rncn $rn $cn ",$m[$rn][$cn], "\n";
        $cnt++ if $m[$rn][$cn] eq '#';
      }
      #print "$r $c $cnt\n";
      if ($cnt == 0 && $cv eq 'L') {
        $new[$r][$c] = '#';
        $ch++;
      }
      if ($cnt >= 4 && $cv eq '#') {
        $new[$r][$c] = 'L';
        $ch++;
      }
    }
  }
  @m = @new;
  print join("\n", map {join ('', @$_)} @m);
}

my $count = 0;
for my $rv (@m) {
  for my $cv (@$rv) {
    $count++ if ($cv eq '#');;
  }
}

print "$count\n";