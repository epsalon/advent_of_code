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
use Math::Utils qw(:utility !log10);    # Useful functions
use Algorithm::DLX;

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my %H;
my $sum=0;

#my $grid = Grid::Dense->read();

while (<>) {
  chomp;
  last if /x/;
  push @A, Grid::Dense->read();
  #my @S;
  #while (<>) {
  #  chomp;
  #  last unless $_;
  #  push @S, $_;
  #}
  #push @A,\@S;
}

sub place {
  my $shape = shift; # grid
  my $rs = shift;
  my $cs = shift;
  my @out;
  for my $r (0..$rs-$shape->rows()) {
    for my $c (0..$cs-$shape->cols()) {
      my @s;
      $shape->iterate(sub {
        my ($sr,$sc,$v) = @_;
        return unless $v eq '#';
        my $ar = $r + $sr;
        my $ac = $c + $sc;
        push @s, $ar*$cs+$ac;
      });
      @s=nsort(@s);
      push @out,join(',', @s);
    }
  }
  return @out;
}

sub placeall {
  my $shape = shift;
  my @g = @_;
  my @out;
  for my $i (0..1) {
    for my $j (0..3) {
      push @out, place($shape,@g);
      $shape->rot90R();
    }
    $shape->flipH();
  }
  @out = uniq(sort {$a cmp $b} @out);
  return @out;
}

sub dbgplace {
  my $i=0;
  for my $s (@A) {
    say "shape ".$i++.":\n";
    my @p = placeall($s,5,6);
    for my $g (@p) {
      for my $r (0..4) {
        for my $c (0..5) {
          print substr($g,$r*6+$c,1);
        }
        print "\n";
      }
      print "\n";
    }
  }
}

sub dbgp {
  my $p=shift;
  my $rs=shift;
  my $cs=shift;
  my @p = split(',', $p);
  for my $i (0..$rs*$cs-1) {
    print "\n" unless $i % $cs;
    if (@p && $p[0] == $i) {
      print '#'; shift @p;
    } else {
      print ".";
    }
  }
  print "\n";
}

do {
  print;
  chomp;
  my ($sz,$ns) = split(': ');
  my ($cs,$rs) = split('x', $sz);
  my @ns = split(' ', $ns);
  dbg(\@ns);
  my $dlx = Algorithm::DLX->new();
  my @grid;
  for my $r (0..$rs-1) {
    for my $c (0..$cs-1) {
      say "adding column g$r,$c";
      push @grid, $dlx->add_column();
    }
  }
  my @shapes;
  for my $i (0..$#ns) {
    for my $j (0..$ns[$i]-1) {
      say "adding column s$i,$j";
      push @{$shapes[$i]}, $dlx->add_column();
    }
  }
  my $rows;
  for my $i (0..$#ns) {
    say "i=$i";
    my @pl = placeall($A[$i],$rs,$cs);
    for my $j (0..$ns[$i]-1) {
      for my $p (@pl) {
        my @row_to_add;
        push @row_to_add, $shapes[$i][$j];
        #say "shape $i copy $j p=$p";
        #dbgp($p,$rs,$cs);
        my @pvals = split(',',$p);
        for my $pv (@pvals) {
          push @row_to_add, $grid[$pv];
        }
        #say "row len = ", scalar(@row_to_add);
        $dlx->add_row(undef, @row_to_add); $rows++;
      }
    }
  }
  for my $g (0..$#grid) {
    $dlx->add_row(undef,$grid[$g]); $rows++;
  }
  say "rows = $rows, cols = ",(@grid + @shapes);
  say "solving";
  my $sols = $dlx->solve('number_of_solutions', 1);
  dbg($sols);
  $sum += @$sols;
} while (<>);


out ($sum);
