# $Header: /home/muir/dms/d/RCS/Ref.pm,v 1.1 1994/08/31 21:49:55 muir Exp $


#
# Perl reference manipulation routines.  Currently: compare and copy
#
# Copyright 1994, David Muir Sharnoff
#

package Ref;

require Exporter;

@EXPORT = qw(cmpref copyref);

#
# Attempt to recursively compare to references.
#
# If they are not the same, try to be consistent about 
# returning a positive or negative number so that it can be
# used for sorting.  The sort order is kinda arbitrary.
#

sub cmpref
{ 
	local($A,$B,$ignore_blessings) = @_;

	return 0 if ($A != 0) && ($A == $B);

	return 0 if "STRING:$A" eq "STRING:$B";

	if (! ref($A) && ! ref($B)) {
		return $A <=> $B || $A cmp $B;
	}

	if (! ref($A)) {
		return 1;
	}

	if (! ref($B)) {
		return -1;
	}

	# 
	# These stand for
	#
	# 	real type a
	#	real string a
	#	basic type a
	#	real type a regex
	#
	local($rtA, $rsA, $btA, $rtAr);
	local($rtB, $rsB, $btB, $rtBr);
	$rtA = ref $A;
	$rtB = ref $B;

	unless ($ignore_blessings) {
		return $rtA cmp $rtB if $rtA ne $rtB;  
	}

	($rtAr = $rtA) =~ s/(\W)/\\$1/g;
	($rtBr = $rtB) =~ s/(\W)/\\$1/g;
	$rsA = "$A";
	$rsB = "$B";
	if ($rsA =~ /^$rtA\=([A-Z]+)\(0x[0-9a-f]+\)$/) {
		$btA = $1;
	} else {
		$btA = $rtA;
	}
	if ($rsB =~ /^$rtBr\=([A-Z]+)\(0x[0-9a-f]+\)$/) {
		$btB = $1;
	} else {
		$btB = $rtB;
	}
	return $btA cmp $btB if $btA ne $btB;

	local(@kA, @kB);
	local($eA, $eB);
	local($r);
	local($y);

	if ($btA eq SCALAR) {
		return $$A <=> $$B || $$A cmp $$B;
	} elsif ($btA eq HASH) {

		# Larry, when will calling functions from within
		# sort subroutines work again?

		@kA = sort 
			{
			    $a <=> $b ||
			    "S$a" cmp "S$b" ||
			    (ref(A) ? 
				(ref(B) ? &cmpref($a,$b,$ignore_blessings) : -1) :
				(ref(B) ? 1 : 0))
			}
			keys %$A;
		@kB = sort 
			{
			    $a <=> $b ||
			    "S$a" cmp "S$b" ||
			    (ref(A) ? 
				(ref(B) ? &cmpref($a,$b,$ignore_blessings) : -1) :
				(ref(B) ? 1 : 0))
			}
			keys %$B;

		return ($#kA <=> $#kB) if $#kA != $#kB;

		while (@kA) {
			$eA = shift(@kA);
			$eB = shift(@kB);

			$r = &cmpref($eA,$eB);
			return $r if $r;
			$r = &cmpref(${$A}{$eA}, ${$B}{$eB});
			return $r if $r;
		}
		return 0;
	} elsif ($btA eq ARRAY) {
		#
		# Larry, why are the extra parens needed?  (5a7)
		#
		return (($#{$A}) <=> ($#{$B})) if ($#{$A} != $#{$B});

		for ($y = 0; $y <= $#{$A}; $y++) {
			$r = &cmpref(${$A}[$y], ${$B}[$y]);
			return $r if $r;
		}
		return 0;
	} elsif ($btA eq REF) {
		return &cmpref($$A,$$B);
	} else {
		die "do not know how to compare $A";
	}
}

#
# Make a recursive copy of a reference
#

sub copyref
{
	local($x,$over) = @_;

	$rt = $over ? $over : ref $x;

	local($z);
	local($r);
	local($y);

	if ($rt eq SCALAR) {
		# Would \$$x work?
		$z = $$x;
		return \$z;
	} elsif ($rt eq HASH) {
		$r = {};
		for $y (sort keys %$x) {
			$r->{&copyref($y)} = &copyref($x->{$y});
		}
		return $r;
	} elsif ($rt eq ARRAY) {
		$r = [];
		for ($y = 0; $y <= $#{$x}; $y++) {
			$r->[$y] = &copyref($x->[$y]);
		}
		return $r;
	} elsif ($rt eq REF) {
		$z = &copyref($x);
		return \$z;
	} elsif (! $rt) {
		return $x;
	} elsif (! $over) {
		local($refstr, $reftype, $reftyper);
		$reftype = ref $x;
		($reftyper = $reftype) =~ s/(\W)/\\$1/g;
		$refstr = "$x";
		if ($refstr =~ /^$reftyper\=([A-Z]+)\(0x[0-9a-f]+\)$/) {
			$r = &copyref($x,$reftype);
			bless $r, $reftype;
			return $r;
		} else {
			die "Do not know how to copy $x";
		}
	} else {
		die "do not know how to copy $x";
	}
}


1;
