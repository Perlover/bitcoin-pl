package cfg;

use warnings;
use strict;

my $NAME = 'bitcoin-pl.conf';

our %C = (
	LOG_FILE_NAME		=> 'var/log',
	LOG_FILES		=> 9,

	DB_DS			=> 'dbi:SQLite:dbname=var/db',
	DB_USER			=> '',
	DB_PASS			=> '',
	DB_COMMIT_PERIOD	=> 10 * 60,

	WEB_PORT		=> 8899,
	WEB_PASS		=> 'changeme',
	WEB_PAGE_SIZE		=> 20,

	NET_PERIOD		=> 1 * 60,
	NET_PEERS		=> '127.0.0.1:8333,127.0.0.1:18883',
);

sub cfg::var::TIEHASH { bless {}, $_[0] }
sub cfg::var::FETCH { exists $C{$_[1]} ? $C{$_[1]} : die "no cfg var $_[1]" }

tie our %var, 'cfg::var';

sub load_ {
	if (open my $f, $NAME) {
		while (<$f>) {
			next if /^[;#\*]|^\s*$/;
			/^\s*(\S*)\s*=\s*(.*?)\s*$/
				or die "bad config line $_\n";
			$C{uc $1} = $2;
			warn "info \U$1\E = $2\n";
		}
	} else {
		warn "info no config file $NAME, using defaults";
	}
}

1;