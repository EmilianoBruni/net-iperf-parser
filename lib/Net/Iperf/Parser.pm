package Net::Iperf::Parser;

use Mojo::Base::Tiny -base;

has start          => 0;
has end            => 0;
has is_valid       => 1;
has is_process_avg => 1;
has speed          => 0;

sub duration {
    my $s = shift;
    return $s->end - $s->start;
}

sub is_global_avg {
    my $s = shift;
    return ( $s->is_process_avg && $s->start == 0 && $s->end > 5 ) || 0;
}

sub speedk {
    return shift->speed / 1024;
}

sub speedm {
    return shift->speed / ( 1024 * 1024 );
}

sub dump {
    my $s = shift;

    my @fld = qw/is_valid start end duration speed speedk speedm
        is_process_avg is_global_avg/;

    my $ret = "{\n";

    foreach (@fld) {
        $ret .= "\t$_ => " . $s->$_ . ",\n";
    }

    $ret .= '}';

    return $ret;

}

sub parsecsv {
    my $s   = shift;
    my $row = shift || '';
    if ( $row =~ /\,/ ) {
        $s->{is_valid} = 1;
        my @itms = split( /,/, $row );

        my $t_range = $itms[6];
        ( $s->{start}, $s->{end} ) = map $_ + 0, split( /-/, $t_range );

        $s->{is_process_avg} = ( $itms[5] == -1 || 0 );

        #$s->{speed} = ($itms[-1] / $s->duration);
        $s->{speed} = $itms[-1] + 0;
    } else {
        $s->{is_valid} = 0;
    }
}

sub parse {
    my $s   = shift;
    my $row = shift || '';
    if ( $row =~ /^\[((\s*\d+)|SUM)\]\s+\d/ ) {
        $s->{is_valid} = 1;
        my @itms;
        $row =~ /([\d\.]+-\s*[\d\.]+)\s+sec/;
        my $t_range = $1;
        ( $s->{start}, $s->{end} ) = map $_ + 0, split( /-/, $t_range );

        $s->{is_process_avg} = ( $row =~ /^\[SUM\]/ || 0 );
        $row =~ /\s+([\d\.]+)\s+(\w+)\/sec/;
        if ( $2 eq 'Mbits' ) {
            $s->{speed} = ( $1 + 0 ) * 1024 * 1024;
        } else {
            $s->{speed} = ( $1 + 0 ) * 1024;
        }
    } else {
        $s->{is_valid} = 0;
    }
}

1;

__END__

# ABSTRACT: Parse a single iperf line result

=pod

=encoding UTF-8

=begin :badge

=begin html

<p>
    <a href="https://github.com/emilianobruni/net-iperf-parser/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/net-iperf-parser/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/net-iperf-parser">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/net-iperf-parser">
</p>

=end html

=end :badge

=head1 SYNOPSIS

  use Net::Iperf::Parser;

  my $p = new Net::Iperf::Parser;

  my @rows = `iperf -c iperf.volia.net -P 2`;

  foreach (@rows) {
    $p->parse($_);
    print $p->dump if ($p->is_valid && $p->is_global_avg);
  }

and result is something like this

  {
      is_valid          => 1,
      start             => 0,
      end               => 10,
      duration          => 10,
      speed             => 129024,
      speedk            => 126,
      speedm            => 0.123046875,
      is_process_avg    => 1,
      is_global_avg     => 1,
  }


=head1 DESCRIPTION

Parse a single iperf line result in default or CSV mode

=head1 METHODS

=method start

Return the start time

=method end

Return the end time

=method is_valid

Return if the parsed row is a valid iperf row

=method is_process_avg

Return if the row is a process average value

=method is_global_avg

Return if the row is the last summary value

=method speed

Return the speed calculated in bps

=method speedk

Return the speed calculated in Kbps

=method speedm

Return the speed calculated in Mbps

=method dump

Return a to_string version of the object (like a Data::Dumper::dumper)

=method parse($row)

Parse a single iperf line result

=method parsecsv($row)

Parse a single iperf line result in CSV mode (-y C)

=head1 SEE ALSO

L<iperf|https://iperf.fr/>

=cut
