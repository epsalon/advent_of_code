package Grid::Dense;

use strict;
use warnings;
use Term::ANSIColor qw(:constants);
use Storable qw(dclone);
use Carp;

sub new {
  my ($class, $array) = @_;
  return bless {
      transpose => 0,
      flipH => 0,
      flipV => 0,
      data => dclone($array),
      data_rows => scalar(@{$array}),
      data_cols => scalar(@{$array->[0]}),
  };
}

sub read {
  my ($class, $fh) = @_;
  $fh = \*ARGV unless $fh;
  my @A;
  while (my $line = <$fh>) {
      chomp $line;
      last unless $line;
      push @A, [split('', $line)];
  }
  return new($class, \@A);
}

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

sub rows {
  my $self = shift;
  return $self->{transpose} ? $self->{data_cols} : $self->{data_rows};
}

sub cols {
  my $self = shift;
  return $self->{transpose} ? $self->{data_rows} : $self->{data_cols};
}

sub translate_coord {
  my $self = shift;
  my $r = shift;
  my $c = shift;
  $r = $self->rows() - 1 - $r if $self->{flipV};
  $c = $self->cols() - 1 - $c if $self->{flipH};
  ($r,$c) = ($c,$r) if ($self->{transpose});
  if ($r < 0 || $c < 0 || $r >= $self->{data_rows} || $c >= $self->{data_cols}) {
    croak("[$r,$c] out of bounds");
  }
  return ($r,$c);
}

sub bounds {
  my $self = shift;
  my $r = shift;
  my $c = shift;
  ($r,$c) = ($c,$r) if ($self->{transpose});
  if ($r < 0 || $c < 0 || $r >= $self->{data_rows} || $c >= $self->{data_cols}) {
    return undef;
  }
  return 1;
}

sub at {
  my $self = shift;
  my $r = shift;
  my $c = shift;
  ($r,$c) = $self->translate_coord($r,$c);
  return $self->{data}[$r][$c];
}

sub set {
  my $self = shift;
  my $r = shift;
  my $c = shift;
  my $v = shift;
  ($r,$c) = $self->translate_coord($r,$c);
  $self->{data}[$r][$c] = $v;
  return $self;
}

sub to_str {
  my $self = shift;
  my @hilite = @_;
  my $ostr;

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
  for my $c (0..$self->cols()-1) {
    $ostr.= $c % 10 ? ' ':$c/10;
  }
  $ostr.= "\n     ";
  for my $c (0..$self->cols()-1) {
    $ostr.= $c % 10;
  }
  $ostr.= "\n";
  for my $r (0..$self->rows()-1) {
    $ostr.= sprintf("%4d ", $r);
    for my $c (0..$self->cols()-1) {
      my $v = $self->at($r,$c);
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

sub iterate {
  my $self = shift;
  my $iterator = shift;
  for my $r (0..$self->rows()-1) {
      for my $c (0..$self->cols()-1) {
          my $v = $self->at($r,$c);
          $iterator->($r, $c, $v);
      }
  }
}

sub as_array {
  my $self = shift;
  my @A;
  for my $r (0..$self->rows()-1) {
    my @row;
    for my $c (0..$self->cols()-1) {
      push @row, $self->at($r,$c);
    }
    push @A, \@row;
  }
  return wantarray ? @A : \@A;
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
