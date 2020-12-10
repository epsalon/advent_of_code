#!/usr/bin/perl -w
use strict;

my %BAG;

sub DFS {
  my ($cur,$seen,$target) = @_;
  print "CUR = $cur SEEN = ".join(',', keys %$seen)."\n";
  $seen->{$cur} = 1;
  my $nexts = $BAG{$cur} || [];
  for my $n (@$nexts) {
    next if ($seen->{$n});
    if ($n eq $target) {
      return 1;
    }
    if (DFS($n, $seen, $target)) {
      return 1;
    }
  }
  return 0;
}

sub DFSCount {
  my ($cur,$seen) = @_;
  print "CUR = $cur SEEN = ".join(',', keys %$seen)."\n";
  #$seen->{$cur} = 1;
  my $nexts = $BAG{$cur} || [];
  my $sum = 1;
  for my $n (@$nexts) {
    my ($nb, $cnt) = @$n;
    $sum += $cnt * DFSCount($nb, $seen)
  }
  return $sum;
}


while (<>) {
  print;
  chomp;
  unless (m{^([\w\s]+\w)\s+bags contain (.+)\.$}o) {
    print "ERR $_\n";
  }
  next if ($2 eq "no other bags");
  my $out = $1;
  my @inbags = split(/,\s*/,$2);
  my @ret;
  for my $inbag (@inbags) {
    $inbag =~ m{(\d+) ([\w\s]+\w) bag(s?)};
    push @ret, [$2, $1];
  }
  $BAG{$out} = \@ret;
}

while (my ($k,$v) = each %BAG) {
  print "$k => ", join(',', @$v), "\n";
}

#my $c = 0;

#for my $b (keys %BAG) {
#  $c += DFS($b, {}, "shiny gold")
#}

# print "$c\n";

print ((DFSCount("shiny gold", {})-1)."\n");
