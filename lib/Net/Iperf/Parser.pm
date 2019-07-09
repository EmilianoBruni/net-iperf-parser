package Net::Iperf::Parser;

# ABSTRACT: Parse a single iperf line result

use Moose;
use namespace::autoclean;

has is_valid        => ( is => 'ro', isa => 'Bool', default => 1 );
has start           => ( is => 'ro', isa => 'Int', default => 0  );
has end             => ( is => 'ro', isa => 'Int', default => 0  );
has speed           => ( is => 'ro', isa => 'Num', default => 0  );
has is_process_avg  => ( is => 'ro', isa => 'Bool', default => 1 );

sub parsecsv {
    my $s       = shift;
    my $row     = shift || '';
    if ($row =~ /\,/) {
        $s->{is_valid} = 1;
        my @itms = split(/,/,$row);

        my $t_range = $itms[6];
        ($s->{start},$s->{end}) = map $_+0, split(/-/, $t_range);

        $s->{is_process_avg} = ($itms[5] == -1 || 0);
        #$s->{speed} = ($itms[-1] / $s->duration);
        $s->{speed} = $itms[-1] + 0;
    } else {
        $s->{is_valid} = 0;
    }
}

sub parse {
    my $s       = shift;
    my $row     = shift || '';
    if ($row =~ /^\[((\s*\d+)|SUM)\]\s+\d/) {
        $s->{is_valid} = 1;
        my @itms;
        $row =~ /([\d\.]+-\s*[\d\.]+)\s+sec/;
        my $t_range = $1;
        ($s->{start},$s->{end}) = map $_+0, split(/-/, $t_range);

        $s->{is_process_avg} = ($row =~ /^\[SUM\]/ || 0);
        $row =~/\s+([\d\.]+)\s+(\w+)\/sec/;
        if ($2 eq 'Mbits') {
            $s->{speed} = ($1+0) * 1024 * 1024;
        } else {
            $s->{speed} = ($1+0) * 1024;
        }
    } else {
        $s->{is_valid} = 0;
    }
}

sub duration {
    my $s   = shift;
    return $s->end - $s->start;
}

sub is_global_avg {
    my $s   = shift;
    return ($s->is_process_avg && $s->start == 0 && $s->end > 5) || 0;
}

sub speedk {
    return shift->speed / 1024;
}

sub speedm {
    return shift->speed / (1024 * 1024);
}

sub dump {
    my $s = shift;

    my @fld = qw/is_valid start end duration speed speedk speedm
        is_process_avg is_global_avg/;

    my $ret = "{\n";

    foreach(@fld) {
        $ret .= "\t$_ => " . $s->$_ . ",\n";
    }

    $ret .= '}';

    return $ret;

}

__PACKAGE__->meta->make_immutable;

1;
