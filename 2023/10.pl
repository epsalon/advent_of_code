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
use utf8::all;
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

# Print and array highlighting some cells
# Args:
#   - array ref, row, col, row, col, ...
#   - array ref, "row,col", "row,col", ...
#   - array ref, array of [row, col, row, col, ...]
#   - array ref, array of ["row,col", "row,col", ...]
#   - array ref, array of [[row, col, color?], ...]
#   - array ref, array of [["row,col", color?], ...]
sub hilite {
  my $arr = shift;
  my @hilite = @_;

  # If neighbor array ref, deref
  if (@hilite == 1 && ref($hilite[0])) {
    @hilite = @{$hilite[0]};
  }

  # If the array is raw coords turn into array of [row, col]
  if (@hilite && !ref($hilite[0])) {
    my $h1 = $hilite[0];
    if ($h1 =~ /^\d+,\d+$/o) {
      # "row,col"
      @hilite = map {/^(\d+),(\d+)$/o; [$1,$2]} @hilite;
    } else {
      # row, col, row, col
      @hilite = pairs(@hilite);
    }
  }

  my %hilite;
  for my $h (@hilite) {
    my ($r, $c, $v) = @$h;
    $hilite{"$r,$c"}=($v || BOLD . ON_RED);
  }

  my $maxlen = 0;
  for my $r (@$arr) {
    for my $c (@$r) {
      $maxlen=length($c) if length($c) > $maxlen;
    }
  }
  for my $r (0..$#$arr) {
    my $ra = $arr->[$r];
    for my $c (0..$#$ra) {
      my $v = $ra->[$c];
      print $hilite{"$r,$c"} || '';
      printf("%${maxlen}s", $v);
      print RESET;
    }
    print "\n";
  }
  print "\n";
}

my $ADDSPACE = 0;

# Parse input

my @A;
while (<>) {
  chomp;
  last unless $_;
  if ($ADDSPACE) {
    push @A, [map {($_,'-')} split('')];
    push @A, [('|',' ') x length($_)];
  } else {
    push @A, [split('')];
  }
}

# Utility constants
no warnings 'qw';
my %DIRS = qw/D 1,0 L 0,-1 U -1,0 R 0,1/;
my %CHARS = qw/| DDUU - LLRR L LUDR 7 RDUL F URLD J RUDL/;
my %RCHARS;
for my $k (keys %CHARS) {
  my ($a,$b,$c,$d) = split ('', $CHARS{$k});
  delete $CHARS{$k};
  $CHARS{$k}{$a} = $b;
  $CHARS{$k}{$c} = $d;
  $RCHARS{"$a$b"} = $k;
  $RCHARS{"$c$d"} = $k;
}

# Find start
my ($sr,$sc);
for my $r (0..$#A) {
  for my $c (0..$#{$A[0]}) {
    if ($A[$r][$c] eq 'S') {
      ($sr,$sc) = ($r,$c);
    }
  }
}

# Find loop
my %l;
DLOOP: for my $sd (qw/L D U/) {
  my ($row,$col) = ($sr,$sc);
  my $d = $sd;
  %l=();
  while (!$l{"$row,$col"}) {
    $l{"$row,$col"}=$d;
    my $dir = [split(',', $DIRS{$d})];
    $row+=$dir->[0]; $col+=$dir->[1];
    my $ch = $A[$row][$col];
    last if ($ch eq 'S');
    unless ($CHARS{$ch}{$d}) {
      next DLOOP;
    }
    $d = $CHARS{$ch}{$d};
  }
  # Clean up the "S"
  $A[$row][$col] = $RCHARS{"$d$sd"};
  last DLOOP;
}

# Output part 1
#hilite(\@A,keys %l);
out (scalar(%l)/($ADDSPACE?4:2));

# Scan for "inside"
my @l;
my $sum;
for my $r (0..$#A) {
  my $out = 1;
  my $corner = 'X';
  for my $c (0..$#{$A[0]}) {
    my $ch = $l{"$r,$c"} ? $A[$r][$c] : 0;
    if ($ch eq '|') {
      $out=!$out;
    }
    if ($ch =~ /[LF]/) {
      $corner = $ch;
    }
    if ($ch eq '7' && $corner eq 'L') {
      $out=!$out;
    }
    if ($ch eq 'J' && $corner eq 'F') {
      $out=!$out;
    }
    if (!$out && !$ch) {
      push @l,"$r,$c";
      unless ($ADDSPACE && ($r&1 || $c&1)) {
        $sum++;
      }
    }
  }
  die unless $out;
}

# Output part 2
#hilite(\@A,@l);
out($sum);

if ($ADDSPACE) {
  for my $r (0..$#A) {
    for my $c (0..$#{$A[0]}) {
      if (!$l{"$r,$c"} && ($r&1 || $c&1)) {
        $A[$r][$c] = ' ';
      }
    }
  }
}

@A = map {[map {tr/.LFJ7|-/·└┌┘┐│─/;$_} @$_]} @A;

#viz
hilite(
  \@A,
  (map {[split(',',$_), BOLD.ON_RED]} (keys %l)),
  (map {[split(',',$_), BOLD.ON_BLUE]} @l));
