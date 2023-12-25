#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my @A;

while (<>) {
  #print;
  chomp;
  push @A, $_;
}

# my @sorted = sort {$a <=> $b} @A;

my @neigh = ([-1,-1], [-1,0], [-1,1], [0,-1], [0, 1], [1,-1], [1,0], [1,1]);

my @m = map {my @r = split(//); \@r} @A;

my %viz;

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
      BIG: for my $n (@neigh) {
        my ($rd, $cd) = @$n;
        my $d = 1;
        my ($rn,$cn);
        my $cur;
        if ($viz{"$r,$c,$rd,$cd"}) {
          ($rn,$cn) = @{$viz{"$r,$c,$rd,$cd"}};
          $cur = $m[$rn][$cn];
        } else {
          do {
            $rn = $r + $rd * $d;
            next BIG if ($rn < 0 || $rn > $#m);
            $cn = $c + $cd * $d;
            next BIG if ($cn < 0 || $cn > $#$rv);
            $d++;
            #print "rncn = $rn $cn\n";
            $cur = $m[$rn][$cn];
          } while ($cur eq '.');
          $viz{"$r,$c,$rd,$cd"} = [$rn, $cn];
        }
        $cnt++ if $cur eq '#';
      }
      #print "$r $c $cnt\n";
      if ($cnt == 0 && $cv eq 'L') {
        $new[$r][$c] = '#';
        $ch++;
      }
      if ($cnt >= 5 && $cv eq '#') {
        $new[$r][$c] = 'L';
        $ch++;
      }
    }
  }
  @m = @new;
  #print join("\n", map {join ('', @$_)} @m), "\n\n$ch\n\n";
}

my $count = 0;
for my $rv (@m) {
  for my $cv (@$rv) {
    $count++ if ($cv eq '#');;
  }
}

print "$count\n";
