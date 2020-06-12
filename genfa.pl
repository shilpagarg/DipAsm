#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: find . -name p_ctg_cns.fa | ./genfa.pl <prefix>\n" if @ARGV == 0;

my $prefix = shift(@ARGV);
my %h = ();
my $n = 0;
my @out;

open($out[0], ">$prefix-H1.fasta") || die;
open($out[1], ">$prefix-H2.fasta") || die;

while (<>) {
	chomp;
	my $fn = $_;
	die unless $fn =~ /([^\s\/]+)-SCAFF-H([12])/;
	my $fh = $out[$2 - 1];
	$h{$1} = ++$n if !defined($h{$1});
	my $p = sprintf("%s-S%.5d-H%d", $prefix, $h{$1}, $2);
	open(FH, $fn) || die;
	while (<FH>) {
		if (/^>(\S+)/) {
			print $fh ">$p-$1\n";
		} else {
			print $fh $_;
		}
	}
	close(FH);
}

close($out[0]);
close($out[1]);
