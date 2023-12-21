package Grid::Sparse;

use strict;
use warnings;
use Storable qw(dclone);
use Carp;
use Data::Dumper;

our @ISA = qw/Grid::Base/;

sub _clean {
  my $in = shift;
  if (ref($in)) {
    return @$in;
  } else {
    $in =~ /^(-?\d+)\D(-?\d+)$/ or croak "Bad index '$in'";
    return ($1,$2);
  }
}

sub _put {
  my ($self,$r,$c,$v) = @_;
  if (!defined($v) || (defined($self->{default}) && $v eq $self->{default})) {
    delete $self->{data}{"$r,$c"};
    return;
  }
  $self->{data}{"$r,$c"} = $v;
  $self->{min_r} = $r if (!defined($self->{min_r}) || $r < $self->{min_r});
  $self->{min_c} = $c if (!defined($self->{min_c}) || $c < $self->{min_c});
  $self->{max_r} = $r if (!defined($self->{max_r}) || $r > $self->{max_r});
  $self->{max_c} = $c if (!defined($self->{max_c}) || $c > $self->{max_c});
}

sub new {
  my ($class, @data) = @_;
  my %dhash;
  my $self = bless {
      transpose => 0,
      flipH => 0,
      flipV => 0,
      data => {},
  };
  return $self unless @data;
  if (ref($data[0]) eq 'HASH') {
    while (my ($k,$v) = each %{$data[0]}) {
      $self->_put(_clean($k), $v);
    }
  } else {
    my $darr = ref($data[0]) eq 'ARRAY' ? $data[0] : \@data;
    for my $v (@$darr) {
      $self->_put(_clean($v), 1);
    }
  }
  return $self;
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
    return ($r, $c, $v);
  } else {
    if (wantarray) {
      return ($r, $c, undef);
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
  $self->_put($self->translate_coord(@_));
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
  my $ret = Grid::Sparse->new(\%ret);
  $ret->{default} = $self->{default} if $self->{default};
  return $ret;
}

sub get_bounds {
  my $self = shift;
  my ($min_r, $min_c, $max_r, $max_c) = map {$self->{$_}} (
    $self->{transpose} ? qw/min_c min_r max_c max_r/ : qw/min_r min_c max_r max_c/);
  ($min_r, $max_r) = (-$max_r, -$min_r) if $self->{flipV};
  ($min_c, $max_c) = (-$max_c, -$min_c) if $self->{flipH};
  return ($min_r, $min_c, $max_r, $max_c);
}

sub to_dense {
  my $self = shift;
  my $default = shift;
  my ($min_r, $min_c, $max_r, $max_c) = $self->get_bounds();
  my @ret;
  for my $r ($min_r..$max_r) {
    my @ret_r;
    for my $c ($min_c..$max_c) {
      push @ret_r, ($self->at($r,$c) // $default // $self->{default});
    }
    push @ret, \@ret_r;
  }
  return Grid::Dense->new(\@ret);
}

1;

__END__
