use strict;

use Time::HiRes qw( gettimeofday );

select(STDOUT); $| = 1;     

my $TIMEVAL_T = "LL";

my $delay;
if ($#ARGV == 0) {
	$delay = int($ARGV[0]);
	if ($delay < 1) {
		$delay = 1;
	}
} else {
	$delay = 1;
}


open(PROC, "</proc/net/dev") || die "unable to open /proc/net/dev for reading: $!\n";

$_ = <PROC>;
if ($_ !~ m#^[^|]+\|\s*Receive\s*\|\s*Transmit\s*$#) {
	die "don't understand first line of /proc/net/dev";
}
$_ = <PROC>;
my ($r_fields, $t_fields) = m#^[^|]+\|([^|]+)\|([^|]+)$#;
my @fields = map { "r_" . $_ } split(' ', $r_fields);
push(@fields, map { "t_" . $_ } split(' ', $t_fields));

close(PROC);

my %prev_stats;

printf "%6s %10s %9s %10s %9s\n", "iface", "rx bytes/s", "rx pkt/s", "tx bytes/s", "tx pkt/s";

my $actual_delay;

while (1) {
	open(PROC, "</proc/net/dev") || die "unable to open /proc/net/dev for reading: $!\n";

	
	$_ = <PROC>;
	$_ = <PROC>;

	my $non_zero_iface = 0;
	my %totals;
	$totals{'r_bytes'} = 0;
	$totals{'r_packets'} = 0;
	$totals{'t_bytes'} = 0;
	$totals{'t_packets'} = 0;

	while (<PROC>) {
		my ($iface, $rest) = m#^\s*(\S+):(.*)$#;
		my @data = split(' ', $rest);

		my %delta;
		my $non_zero_field = 0;

		foreach my $i (@fields) {
			if (!defined($prev_stats{$iface}{$i})) {
				$prev_stats{$iface}{$i} = 0;
			}
			my $x = shift @data;
			$delta{$i} = $x - $prev_stats{$iface}{$i};
			if ($delta{$i} < 0) {
				
				$delta{$i} += 2*(1<<31);
			}
			if ($delta{$i} != 0) {
				$non_zero_field = 1;
				$non_zero_iface = 1;
			}
			$prev_stats{$iface}{$i} = $x;
		}

		next unless $non_zero_field;

		if (defined($actual_delay)) {
			$totals{'r_bytes'} += int($delta{'r_bytes'} / $actual_delay + 0.5);
			$totals{'r_packets'} += int($delta{'r_packets'} / $actual_delay + 0.5);
			$totals{'t_bytes'} += int($delta{'t_bytes'} / $actual_delay + 0.5);
			$totals{'t_packets'} += int($delta{'t_packets'} / $actual_delay + 0.5);

			printf "%6s %10u %9u %10u %9u", $iface,
				int($delta{'r_bytes'} / $actual_delay + 0.5),
				int($delta{'r_packets'} / $actual_delay + 0.5),
				int($delta{'t_bytes'} / $actual_delay + 0.5),
				int($delta{'t_packets'} / $actual_delay + 0.5);
			
			foreach my $i (@fields) {
				next if $i eq 'r_bytes';
				next if $i eq 'r_packets';
				next if $i eq 't_bytes';
				next if $i eq 't_packets';
				next if $delta{$i} == 0;
				print " $i $delta{$i}";
			}
			
			print "\n";
		}
	}
	close(PROC);

	if ($non_zero_iface == 0) {
		print "no traffic\n";
	}
	elsif (defined($actual_delay)) {
		printf "%6s %10u %9u %10u %9u\n", "total",
			$totals{'r_bytes'},
			$totals{'r_packets'},
			$totals{'t_bytes'},
			$totals{'t_packets'};
	}

	my @start = gettimeofday;
	sleep($delay);
	my @done = gettimeofday;
	$actual_delay = ($done[0] + $done[1] / 1_000_000) - ($start[0] + $start[1] / 1_000_000);

	my $delta = $actual_delay - $delay;
	if ($delta > 0.2 or $delta < -0.2) {
		printf "asked for %d second sleep, got %f\n", $delay, $actual_delay;
	}
}