package UF;
use strict;

sub new {
    my ($class, $elements) = @_;
    my (%H,%C);
    for my $e (@$elements) {
        $H{$e}=$e;
        $C{$e}=1;
    }
    return bless {
        rep => \%H,
        cnt => \%C
    }
}

sub find {
    my ($class, $e) = @_;
    my $H = $class->{rep};
    my @es;
    while ($e ne $H->{$e}) {
        push @es, $e;
        $e = $H->{$e};
    }
    for my $x (@es) {
        $H->{$x} = $e;
    }
    return $e;
}

sub count {
    my ($class, $e) = @_;
    my $r = $class->find($e);
    return $class->{cnt}{$r};
}

sub union {
    my ($class, $e1, $e2) = @_;
    $e1 = $class->find($e1);
    $e2 = $class->find($e2);
    if ($e1 eq $e2) {
        return 0;
    }
    my $c1 = $class->count($e1);
    my $c2 = $class->count($e2);
    if ($c1 > $c2) {
        ($e1,$e2) = ($e2,$e1);
    }
    $class->{rep}{$e1}=$e2;
    $class->{cnt}{$e2}=$c1 + $c2;
    delete $class->{cnt}{$e1};
    return 1;
}

1;
