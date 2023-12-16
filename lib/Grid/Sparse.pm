package Grid::Sparse;

use strict;
use warnings;
use Storable qw(dclone);
use Carp;

our @ISA = qw/Grid::Base/;

sub _clean {
  my $in = shift;
  if (ref($in)) {
    return $in->[0].",".$in->[1];
  } else {
    $in =~ s/^(-?\d+)\D(-?\d+)$/$1,$2/o;
    return $in;
  }
}

sub new {
  my ($class, @data) = @_;
  my $dhash = $data[0];
  if (ref($data[0]) eq 'HASH') {
    $dhash = dclone($data[0]);
  } else {
    my $darr = ref($data[0]) eq 'ARRAY' ? $data[0] : \@data;
    my %dhash = map { _clean($_) => 1 } @$darr;
    $dhash = \%dhash;
  }
  return bless {
      transpose => 0,
      flipH => 0,
      flipV => 0,
      data => $dhash,
  };
}

sub translate_coord {
  my $self = shift;
  my ($r,$c,$v) = @_;
  if (ref($r)) {
    ($r,$c,$v) = (@$r,$c);
  } elsif ($r =~ /^(-?\d+)\D(-?\d+)$/) {
    ($r,$c,$v) = ($1,$2,$c);
  }
  $r = -$r if $self->{flipV};
  $c = -$c if $self->{flipH};
  ($r,$c) = ($c,$r) if ($self->{transpose});
  if (defined($v)) {
    croak "Bad argument count" unless wantarray;
    return ("$r,$c", $v);
  } else {
    if (wantarray) {
      return ("$r,$c", undef);
    } else {
      return "$r,$c";
    }
  }
}

sub at {
  my $self = shift;
  return $self->{data}{$self->translate_coord(@_)};
}

sub set {
  my $self = shift;
  my ($coord,$v) = $self->translate_coord(@_);
  if (defined($v)) {
    $self->{data}{$coord} = $v;
  } else {
    delete $self->{data}{$coord};
  }
  return $self;
}

sub iterate {
  my $self = shift;
  my $iterator = shift;
  while (my ($k,$v) = each %{$self->{data}}) {
    my ($r,$c) = split(',', $k);
    ($r,$c) = ($c,$r) if ($self->{transpose});
    $r = -$r if $self->{flipV};
    $c = -$c if $self->{flipH};
    local $_ = $v;
    $iterator->($r, $c, $v);
  }
}

sub map {
  my $self = shift;
  my $iterator = shift;
  my %ret;
  $self->iterate(sub {
    my ($r, $c, $v) = @_;
    my ($nr,$nc,$nv) = $iterator->(@_);
    if (!defined($nc)) {
      ($nr,$nc,$nv) = ($r, $c, $nr);
    } elsif (!defined($nv)) {
      $nv = $v;
    }
    $ret{"$nr,$nc"} = $nv;
  });
  return Grid::Sparse->new(\%ret);
}

sub to_dense {
  my $self = shift;
  my $default = shift;
  my ($min_r, $min_c, $max_r, $max_c);
  $self -> iterate(sub {
    my ($r,$c) = @_;
    $min_r = $r if (!defined($min_r) || $r < $min_r);
    $min_c = $c if (!defined($min_c) || $c < $min_c);
    $max_r = $r if (!defined($max_r) || $r > $max_r);
    $max_c = $c if (!defined($max_c) || $c > $max_c);
  });
  my @ret;
  for my $r ($min_r..$max_r) {
    my @ret_r;
    for my $c ($min_c..$max_c) {
      push @ret_r, ($self->at($r,$c) // $default);
    }
    push @ret, \@ret_r;
  }
  return Grid::Dense->new(\@ret);
}

1;

__END__
