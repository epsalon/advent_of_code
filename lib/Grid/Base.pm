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

sub get_bounds {
  die "Unimplemented 'get_bounds'";
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


sub to_str {
  my $self = shift;
  my @hilite = @_;
  my $ostr;
  my ($min_r, $min_c, $max_r, $max_c) = $self->get_bounds();

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
    my ($r, $c) = @$h;
    $hilite{"$r,$c"}++;
  }

  my $maxlen = 0;
  $self->iterate(sub {
    my ($c) = $_[2];
    $maxlen=length($c) if length($c) > $maxlen;
  });
  $ostr.= "     ";
  if ($maxlen < 2) {
    for my $c ($min_c..$max_c) {
      $ostr.= abs($c) % 10 ? (' '):$c/10;
    }
    $ostr.= "\n     ";
  }
  for my $c ($min_c..$max_c) {
    $ostr.= substr(sprintf("%${maxlen}d", $c),-$maxlen);
  }
  $ostr.= "\n";
  for my $r ($min_r..$max_r) {
    $ostr.= sprintf("%4d ", $r);
    for my $c ($min_c..$max_c) {
      my $v = $self->at($r,$c) // $self->{default} // ' ';
      $ostr.= BOLD . ON_RED if $hilite{"$r,$c"};
      $ostr.=sprintf("%${maxlen}s", $v);
      $ostr.= RESET if $hilite{"$r,$c"};
    }
    $ostr.= "\n";
  }
  $ostr.= "\n";
  return $ostr;
}

sub print {
  my $self=shift;
  print $self->to_str(@_);
}


1;

__END__
