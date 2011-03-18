#! /usr/bin/perl

use warnings;
use strict;
use DBI;

my $dbh = DBI->connect ('dbi:SQLite:dbname=../var/db', '', '', {
	RaiseError	=> 1,
	AutoCommit	=> 0,
});

my $sth = $dbh->prepare ('
	select count(*) from tx
');
#	SELECT * FROM tx_in WHERE tx_hash = ?

$sth->execute ();
#scalar reverse pack 'H*',
#'d5d27987d2a3dfc724e359870c6644b40e497bdc0589a033220fe15429d88599');

print $sth->fetchrow_hashref;
