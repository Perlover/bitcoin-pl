package base58;

use warnings;
use strict;

use ripemd160;

our $ADDRESSVERSION = "\0";

our $BASE = 58;

my @digit = grep !/[0OIl]/, 0..9, 'A'..'Z', 'a'..'z';
die "wtf" if @digit != $BASE;
my %digit; @digit{@digit} = 0..$#digit;

sub mul {
	my ($num, $car) = @_;

	my @c = reverse unpack 'C*', $num;
	for (@c) {
		$_ = $_ * $BASE + $car;
		$car = int $_ / 256;
		$_ %= 256;
	}
	push @c, $car if $car;
	return pack ('C*', reverse @c);
}

sub div {
	my ($num) = @_;

	my $rem = 0;
	my @c = unpack 'C*', $num;
	for (@c) {
		$rem = $_ + $rem * 256;
		$_ = int $rem / $BASE;
		$rem %= $BASE;
	}
	shift @c if !$c[0];
	return pack ('C*', @c), $rem;
}

sub DecodeBase58 {
	my ($enc) = @_;

	$enc =~ s/^($digit[0]*)//;
	my $zer = "\0" x length $1;	
	my $res = '';
	exists $digit{$_} and $res = mul ($res, $digit{$_})
		for $enc =~ /./g;
	return $zer . $res;
}

sub EncodeBase58 {
	my ($num) = @_;

	$num =~ s/^(\0*)//;
	my $zero = length $1;
	my $res = '';
	while (length $num) {
		($num, my $rem) = div ($num);
		$res .= $digit[$rem];
	}
	return $digit[0] x $zero . reverse $res;
}

sub mod { int $_[0] % 2**32 }
sub ror { my ($v, $r) = @_; $v >> $r | $v << 32 - $r }

my @primes = grep { my $c = $_; !grep $c % $_ == 0, 2 .. $c - 1 } 2 .. 311;
my @init = map mod (2**32 * sqrt), @primes[0..7];
my @k = map mod (2**32 * $_ ** (1 / 3)), @primes;

sub sha256_ {
	my ($s) = @_;
	my @h = @init;
	my @s = unpack 'N*', pack 'a*Bx8x!64X4N', $s, 1, 8 * length $s;

	for (0 .. $#s / 16) {
		my @w = @s[$_ * 16 .. $_ * 16 + 15];

		for my $i (16 .. 63) {
			my $s0 = ror ($w[$i - 15], 7) ^ ror ($w[$i - 15], 18)
				^ $w[$i - 15] >> 3;
			my $s1 = ror ($w[$i - 2], 17) ^ ror ($w[$i - 2], 19)
				^ $w[$i - 2] >> 10;
			$w[$i] = mod ($w[$i - 16] + $s0 + $w[$i - 7] + $s1);
		}

		my ($a, $b, $c, $d, $e, $f, $g, $h) = @h;

		for my $i (0 .. 63) {
			my $s0 = ror ($a, 2) ^ ror ($a, 13) ^ ror ($a, 22);
			my $maj = ($a & $b) ^ ($a & $c) ^ ($b & $c);
			my $t2 = $s0 + $maj;
			my $s1 = ror ($e, 6) ^ ror ($e, 11) ^ ror ($e, 25);
			my $ch = ($e & $f) ^ (~$e & $g);
			my $t1 = $h + $s1 + $ch + $k[$i] + $w[$i];

			$h = $g;
			$g = $f;
			$f = $e;
			$e = mod ($d + $t1);
			$d = $c;
			$c = $b;
			$b = $a;
			$a = mod ($t1 + $t2);
		}

		$h[0] = mod ($h[0] + $a);
		$h[1] = mod ($h[1] + $b);
		$h[2] = mod ($h[2] + $c);
		$h[3] = mod ($h[3] + $d);
		$h[4] = mod ($h[4] + $e);
		$h[5] = mod ($h[5] + $f);
		$h[6] = mod ($h[6] + $g);
		$h[7] = mod ($h[7] + $h);
	}
	return pack 'N*', @h;
}

eval { require Digest::SHA };
*sha256 = $@ ? \&sha256_ : \&Digest::SHA::sha256;

sub Hash { sha256 (sha256 ($_[0])) }

sub Hash160 { ripemd160::hash (sha256 ($_[0])) }

sub DecodeBase58Check {
	my ($enc) = @_;

	my $res = DecodeBase58 ($enc);
	my $dec = substr $res, 0, -4;
	substr (Hash ($dec), 0, 4) eq substr ($res, -4)
		or die "base58 check failed";
	return $dec;
}

sub EncodeBase58Check {
	my ($bin) = @_;

	return EncodeBase58 ($bin . substr Hash ($bin), 0, 4);
}

sub AddressToHash160 {
	my ($enc) = @_;

	my $res = DecodeBase58Check ($enc);
	length $res == 21
		or die "bad address length";
	$res =~ s/^(\C)//;
	$1 eq $ADDRESSVERSION
		or die "bad address version";
	return $res;
}

sub Hash160ToAddress { EncodeBase58Check ($ADDRESSVERSION . $_[0]) }

sub PubKeyToAddress { Hash160ToAddress (Hash160 ($_[0])) }

1;
