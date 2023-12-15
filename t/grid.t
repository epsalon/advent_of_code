use Test::More;
use Grid::Dense;
use Data::Dumper;
use feature 'say';

sub expect {
  my $grid = shift;
  my $exp = shift;
  my $test_name = shift;
  my $grid_str = join('|',map {join('',@$_)} $grid->as_array());
  is($grid_str, $exp, $test_name);
}

my $grid;
expect($grid = new Grid::Dense([[qw/1 2 3/],[qw/4 5 6/]]),
       '123|456', 'parse');
expect($grid->transpose(), '14|25|36', 'transpose');
expect($grid->rot90R(), '321|654', 'rotate right');
expect($grid->transpose(), '36|25|14', 'transpose after rot');
expect($grid->rot180(), '41|52|63', 'rot180');
expect($grid->flipV(), '63|52|41', 'flipV');
expect($grid->transpose(), '654|321', 'transpose again');
expect($grid->flipH(), '456|123', 'flipH');
expect($grid->rot90L(), '63|52|41', 'rotate left');

my $grid_str = $grid->to_str();
ok($grid_str =~ /63.*52/os, 'to_str');
ok($grid_str !~ /123/os, 'to_str');

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

done_testing;