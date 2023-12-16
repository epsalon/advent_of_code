package Grid::Base;

use strict;
use warnings;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use Carp;

sub transpose {
  my $self = shift;
  ($self->{transpose}, $self->{flipH}, $self->{flipV}) =
      (!$self->{transpose}, $self->{flipV}, $self->{flipH});
  return $self;
}

sub flipH {
  my $self = shift;
  $self->{flipH} = !$self->{flipH};
  return $self;
}

sub flipV {
  my $self = shift;
  $self->{flipV} = !$self->{flipV};
  return $self;
}

sub rot90R {
  my $self = shift;
  ($self->{transpose}, $self->{flipH}, $self->{flipV}) =
      (!$self->{transpose}, !$self->{flipV}, $self->{flipH});
  return $self;
}

sub rot90L {
  my $self = shift;
  ($self->{transpose}, $self->{flipH}, $self->{flipV}) =
      (!$self->{transpose}, $self->{flipV}, !$self->{flipH});
  return $self;
}

sub rot180 {
  my $self = shift;
  ($self->{flipH}, $self->{flipV}) = (!$self->{flipH}, !$self->{flipV});
  return $self;
}

sub bounds {
  return 1;
}

sub at {
  die "Unimplemented 'at'";
}

sub set {
  die "Unimplemented 'set'";
}

# Find neighbors
# input
#     neigh_arr, row, col
# OR: neigh_arr, "row,col"
# returns
#     array of [row, col, value]
# OR: array of ["row,col", value]
sub neigh {
  my $self = shift;
  my $neigh = shift;
  my $row = shift;
  my $col = shift;
  my $comma;
  if ($row =~ /(\d+)(\D+)(\d+)/) {
    ($row, $comma, $col) = ($1, $2, $3);
  }
  my @out;
  for my $pair (@$neigh) {
    my ($rd, $cd) = @$pair;
    my ($nr, $nc) = ($row + $rd, $col + $cd);
    next unless $self->bounds($nr, $nc);
    if (defined($comma)) {
      push @out, ["$nr$comma$nc", $self->at($nr,$nc)];
    } else {
      push @out, [$nr, $nc, $self->at($nr,$nc)];
    }
  }
  return @out;
}

# Orthogonal
sub oneigh {
  my $self = shift;
  return $self->neigh([[-1,0], [1, 0], [0, -1], [0, 1]], @_);
}

# All neighbors
sub aneigh {
  my $self = shift;
  return $self->neigh([
    [-1, -1], [-1, 0], [-1, 1],
    [ 0, -1],          [ 0, 1],
    [ 1, -1], [ 1, 0], [ 1, 1]], @_);
}

1;

__END__
