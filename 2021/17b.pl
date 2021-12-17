#!/usr/bin/perl -w
use strict;
no warnings 'portable';
use Data::Dumper;
use feature 'say';
use Clipboard;
use List::Util qw/sum min max reduce any all none notall first product uniq/;
use Math::Cartesian::Product;
use Math::Complex;
use List::PriorityQueue;
use Memoize;
use POSIX qw/ceil floor round/;
use GD::Simple;

sub out {
  my $out = shift;
  if (ref($out)) {
    print Dumper($out);
  } else {
    Clipboard->copy_to_all_selections($out);
    print "$out\n";
  }
}

# Numeric sort because sort defaults to lex
# returns new array
sub nsort {
  my $in = \@_;
  if (@$in == 1) {
    $in = $in->[0];
  }
  return sort {$a <=> $b} @$in;
}

sub v_term {
  my $x = shift;
  return 0.5 * (sqrt(8*$x+1)-1);
}

sub y2t {
  my ($vy, $y) = @_;
  return 0.5 * (sqrt(-8 * $y + 4*$vy*$vy + 4 * $vy + 1) + 2* $vy + 1);
}

# v_0 = X/t + (t-1)/2 
sub v {
  my ($t, $x) = @_;
  return $x/$t + ($t-1)/2;
}

sub bounds {
  my ($vv1, $vv2) = @_;
  my ($v1, $v2) = nsort($vv1, $vv2);
  ($v1, $v2) = (ceil($v1), floor($v2));
  if ($v2 >= $v1) {
    return wantarray ? ($v1, $v2+1) : ($v2-$v1+1);
  } else {
    return wantarray ? () : 0;
  }
}

# Read input
$_=<>;
chomp;
my ($x1,$x2,$y1,$y2) = m{x=([-\d]+)\.\.([-\d]+), y=([-\d]+)\.\.([-\d]+)}o or die;

$x1 *= 1000; $x2 *= 1000; $y1 *= 1000; $y2 *= 1000;

my $maxy = max(abs($y1), abs($y2));
my $sy = $y1+$y2<0?-1:1;

# Part 1
print "Max height: ";
out ($sy*$maxy*($sy*$maxy+1)/2);

# X = t * v_0 - (t-1)*t/2 
# X = max_t^2 - max_t^2/2 + max_t/2

# Part 2 analytical solution
my $maxx = max(abs($x1), abs($x2));
my $max_t=int(v_term($maxx));

say "max_t = $max_t";

# Find rectangles
my $max_vy;
my @rects;
my %xs;
my %ys;
for my $t (1..$max_t) {
  my @bx = bounds(v($t, $x1), v($t, $x2));
  my @by = bounds(v($t, $y1), v($t, $y2));
  next unless @bx && @by;
  # say join(',', (@bx, @by));
  push @rects, [@bx, @by];
  $xs{$_}++ for @bx;
  $ys{$_}++ for @by;
  $max_vy = max(@by);
}

# Sort and index
my @xs = nsort(keys %xs);
my @ys = nsort(keys %ys);
for my $i (0..$#xs) {
  $xs{$xs[$i]} = $i;
}
for my $i (0..$#ys) {
  $ys{$ys[$i]} = $i;
}

# Draw output
my $MAX_SIZE = 2000;
my $width = ($xs[-1]-$xs[0]);
my $height = ($ys[-1]-$ys[0]);
my $scale = max(1, max($width, $height) / $MAX_SIZE);
my $dy = ceil($ys[-1]/$scale);
my $img = GD::Simple->new(ceil($width/$scale), ceil($height/$scale));
$img->fgcolor('black');
$img->bgcolor('red');
for my $r (@rects) {
  my ($xx1,$xx2,$yy1,$yy2) = map {round($_/$scale)} @$r;
  $img->rectangle($xx1,$dy-$yy2,$xx2,$dy-$yy1);
}
open my $out, '>', '17-out.png' or die;
binmode $out;
print $out $img->png;

# Compute area
my %grid;
for my $r (@rects) {
  my ($xx1,$xx2,$yy1,$yy2) = @$r;
  my ($xi1,$xi2,$yi1,$yi2) = ($xs{$xx1}, $xs{$xx2}, $ys{$yy1}, $ys{$yy2});
  for my $xi ($xi1..$xi2-1) {
    my ($x,$dx) = ($xs[$xi], $xs[$xi+1] - $xs[$xi]);
    for my $yi ($yi1..$yi2-1) {
      my ($y,$dy) = ($ys[$yi], $ys[$yi+1] - $ys[$yi]);
      my $area = $dx * $dy;
      #say "painting $x,$y size $area ".($grid{$x,$y} ? "(overlap)" : "");
      $grid{$x,$y} = $area;
    }
  }
}
my $total = sum(values %grid);

say "rectangle total = $total";

# Finally, check for all v_y's that align with terminal x
my $term_dx = bounds(v_term($x1), v_term($x2));
say "max v_y=$max_vy term dx = $term_dx";
for my $vy ($max_vy..$maxy) {
  next unless bounds(y2t($vy, $y1), y2t($vy, $y2));
  $total += $term_dx;
}

print "Total area: ";
out($total);