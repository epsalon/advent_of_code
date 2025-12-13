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
use Algorithm::X::DLX;

BEGIN {push @INC, "../lib";}
use AOC ':all';
use Grid::Dense;

$AOC::DEBUG_ENABLED=1;
$|=1;

my @A;
my @SZ;
my @MSZ;
my %H;
my $sum=0;

#my $grid = Grid::Dense->read();

while (<>) {
  chomp;
  last if /x/;
  my $g = Grid::Dense->read();
  push @A, $g;
  my $size;
  $g->iterate(sub{
    $size++ if $_[2] eq '#';
  });
  push @SZ,$size;
  push @MSZ,$g->rows() * $g->cols();
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

while (1) {
  chomp;
  print "$_\n";
  my ($sz,$ns) = split(': ');
  my ($cs,$rs) = split('x', $sz);
  my @ns = split(' ', $ns);
  my $minsize=0;
  my $maxsize=0;
  for my $i (0..$#ns) {
    $minsize += $ns[$i] * $SZ[$i];
    $maxsize += $ns[$i] * $MSZ[$i];
  }
  my $gridsize = $rs*$cs;
  say "minsize=$minsize maxsize=$maxsize gridsize=$gridsize sum=$sum";
  if ($minsize > $gridsize) {
    say "obviously impossible $minsize > $gridsize";
    next;
  } 
  if ($maxsize <= $gridsize) {
    say "trivially possible $maxsize <= $gridsize";
    $sum++;
    next;
  }
  my $nshapes = sum(@ns);
  my $dlx = Algorithm::X::ExactCoverProblem->new($gridsize+$nshapes,undef,$gridsize);
  my $rows=0;
  my $sidx = 0;
  for my $i (0..$#ns) {
    say "i=$i";
    my @pl = placeall($A[$i],$rs,$cs);
    for my $j (0..$ns[$i]-1) {
      for my $p (@pl) {
        #dbgp($p,$rs,$cs);
        my @row_to_add = (split(',',$p), $sidx+$gridsize);
        #say "row $rows = ",join(',', @row_to_add);
        $dlx->add_row(\@row_to_add); $rows++;
      }
      $sidx++;
    }
  }
  say "rows = $rows, cols = ",($gridsize+$nshapes);
  my $solver = Algorithm::X::DLX->new($dlx);
  say "solving";
  my $sols = $solver->get_solver();
  if (my $sol = &$sols()) {
    say "sol = ",join(',', @$sol);
    $sum++;
  } else {
    say "no solutions";
  }
} continue {
  last unless defined($_=<>);
}


out ($sum);
