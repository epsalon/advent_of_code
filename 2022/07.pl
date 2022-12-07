#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

my $A;
my @S;
my $size=0;
my @O;
my $sum;

while (<>) {
  chomp;
NEXT:
  last unless $_;
  my @p = split(' ');
  my ($a,$b,$c) = @p;
  if ($b eq 'cd') {
    if ($c eq '..') {
      $A--;
      push @O, $size;
      $sum += $size if ($size < 100000);
      $size += pop(@S);
    } else {
      $A++;
      push @S, $size;
      $size = 0;
    }
    next;
  }
  # ls
  while (<>) {
    chomp;
    if (/^(\d+)/) {
      $size+=$1;
    } elsif (/^\$/) {
      goto NEXT;
    }
  }
  goto NEXT;
}

while ($A--) {
  push @O, $size;
  $sum += $size if ($size < 100000);
  $size += pop(@S);
}

out($sum);

my $T = $size-40000000;
for my $c (sort {$b <=> $a} @O) {
  $sum = $c if $c > $T;
}

out($sum);
