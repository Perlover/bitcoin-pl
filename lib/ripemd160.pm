package ripemd160;

use warnings;
use strict;

my @K = map int 2**30 * sqrt, 0, 2, 3, 5, 7;
my @k = map int 2**30 * $_**(1/3), 2, 3, 5, 7, 0;

my @p = qw( 7 4 13 1 10 6 15 3 12 0 9 5 2 14 11 8 );
my (@a, @b);
@a = @b = 0..15;
my @R = (@b, map @a=@p[@a], 1..4);
@a = @b = map { (9 * $_ + 5) % 16 } @b;
my @r = (@b, map @a=@p[@a], 1..4);

my @S = qw(
	11 14 15 12 5 8 7 9 11 13 14 15 6 7 9 8
	7 6 8 13 11 9 7 15 7 12 15 9 11 7 13 12
	11 13 6 7 14 9 13 15 14 8 13 6 5 12 7 5
	11 12 14 15 14 15 9 8 9 14 5 6 8 6 5 12
	9 15 5 11 6 8 13 12 5 12 13 14 11 8 5 6
);
my @s = qw(
	8 9 9 11 13 15 15 5 7 7 8 11 14 14 12 6
	9 13 15 7 12 8 9 11 7 7 12 7 6 15 13 11
	9 7 15 11 8 6 6 14 12 13 5 14 13 13 7 5
	15 5 8 11 14 14 6 14 6 9 12 9 12 5 15 8
	8 5 12 9 12 5 14 6 8 13 6 5 15 13 11 11
);

my @H = (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0);

sub u32 {
	my ($n) = @_;

	return $n & 0xffffffff;
}

sub rol {
	my ($R, $N) = @_;

	return u32 $N << $R | $N >> 32 - $R;
}

sub f {
	my ($j, $x, $y, $z) = @_;

	u32	$j <= 15 ? $x ^ $y ^$z :
		$j <= 31 ? ($x & $y) | (~$x & $z) :
		$j <= 47 ? ($x | ~$y) ^ $z :
		$j <= 63 ? ($x & $z) | ($y & ~$z) :
			   $x ^ ($y | ~$z);
}

sub hash {
	my ($str) = @_;

	my $L = length $str;
	$str .=  pack 'Bx'.(63 & 55 - $L).'VV', 1, 8 * $L;
	my @h = @H;
	$str =~ s!(\C{64})!
		my @X = unpack 'V16', $1;
		my ($A, $B, $C, $D, $E) = @h;
		my ($a, $b, $c, $d, $e) = @h;
		my $T;
		for my $j (0 .. 79) {
			$T = u32 rol ($S[$j], u32 $A +
				f ($j, $B, $C, $D) +
				$X[$R[$j]] + $K[$j/16]) + $E;
			$A = $E; $E = $D; $D = rol (10, $C); $C = $B; $B = $T;

			$T = u32 rol ($s[$j], u32 $a +
				f (79 - $j, $b, $c, $d) +
				$X[$r[$j]] + $k[$j/16]) + $e;
			$a = $e; $e = $d; $d = rol (10, $c); $c = $b; $b = $T;
		}
		$T    = u32 $h[1] + $C + $d;
		$h[1] = u32 $h[2] + $D + $e;
		$h[2] = u32 $h[3] + $E + $a;
		$h[3] = u32 $h[4] + $A + $b;
		$h[4] = u32 $h[0] + $B + $c;
		$h[0] = $T;
	!eg;
	return pack 'V5', @h;
}

1;
