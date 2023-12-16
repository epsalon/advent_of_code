use Grid::Dense;
use Data::Dumper;
use Test::More;
use Test::Exception;
use feature 'say';

sub expect {
  my $grid = shift;
  my $exp = shift;
  my $test_name = shift;
  my $grid_str = join('|',map {join('',@$_)} $grid->as_array());
  is($grid_str, $exp, $test_name);
}

sub expect_2d {
  my $arr = shift;
  my $exp = shift;
  my $test_name = shift;
  my $grid_str = join('|',map {join('&',@$_)} @$arr);
  is($grid_str, $exp, $test_name);
}

sub expect_sparse {
  my $grid = shift;
  return expect($grid->to_dense('.'), @_);
}

my $grid;
expect($grid = Grid::Dense->new([[qw/1 2 3/],[qw/4 5 6/]]),
       '123|456', 'parse');
expect($grid->transpose(), '14|25|36', 'transpose');
expect($grid->rot90R(), '321|654', 'rotate right');
expect($grid->transpose(), '36|25|14', 'transpose after rot');
expect($grid->rot180(), '41|52|63', 'rot180');
expect($grid->flipV(), '63|52|41', 'flipV');
expect($grid->transpose(), '654|321', 'transpose again');
expect($grid->flipH(), '456|123', 'flipH');
expect($grid->rot90L(), '63|52|41', 'rotate left');

dies_ok {$grid->at(0,2);} "bounds check";

expect_2d([$grid->oneigh(2,1)],'1&1&2|2&0&4','oneigh');
expect_2d([$grid->aneigh(1,0)],'0&0&6|0&1&3|1&1&2|2&0&4|2&1&1','aneigh');

my $grid_str = $grid->to_str();
ok($grid_str =~ /63.*52/os, 'to_str');
ok($grid_str !~ /123/os, 'to_str (negative)');

my @T;
$grid->iterate(sub {
    my ($r,$c,$v) = @_;
    $T[$r][$c]=$v;
});

expect($grid = new Grid::Dense(\@T), '63|52|41', 'iterate');

pipe RD,WR;
print WR "abc\ndef\n";
close (WR);
expect($grid = Grid::Dense->read(\*RD), "abc|def", "read");
close (RD);

pipe RD,WR;
print WR "abc\ndef\n\nghi\njkl\n";
WR->flush();
expect($grid = Grid::Dense->read(\*RD), "abc|def", "read multi 1");
close (WR);
expect($grid = Grid::Dense->read(\*RD), "ghi|jkl", "read multi 2");
close (RD);

expect_sparse($grid = Grid::Dense->new([[qw/. . . 4/],[qw/. 5 . ./]])->to_sparse('.'),
       '..4|5..', 'to_sparse');

expect_sparse($grid->flipH(), '4..|..5', 'flipH sparse');

expect_sparse($grid->set("1;0",'x'), '4...|..5x', 'set ; sparse');
expect_sparse($grid->transpose(), '4.|..|.5|.x', 'transpose sparse');
expect_sparse($grid->set([-1,2],'y'), '4..|...|.5y|.x.', 'set arr sparse');

expect_sparse($grid->map(sub { ($_[0] * 2, $_[1] * 3) }),
       '4......|.......|.......|.......|...5..y|.......|...x...', 'map coords');

expect_sparse($grid->map(sub {chr(ord($_) + 1);}), '5..|...|.6z|.y.', 'map vals');

done_testing;