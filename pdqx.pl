#! /usr/bin/perl -w
#
# Extract PDQ node and stream tokens from PDQ_Report() file.
# Created by NJG on Monday, December 04, 2017

use strict;
use Data::Dumper;

# open Report file and scan for line containing the following keywords ...
my $keywords = quotemeta "Node Sched Resource   Workload";
my $file = "diskopt-rpt.txt";
my $infile = "$file";
open(INFILE, "< $infile") or die "can't open $infile: $!";

my @chunks;
my $started = 0;
my %nodekv; # hash of lists


while (<INFILE>) {
	my $x = $_;
	
	if ($x =~ /$keywords/ && !$started) {
		$started = 1;
		next; 
	}
	
	if ($started) {		
		if ($x =~  /---/) {
		    # skip heads and underlining
			next; 
		}
		
		if ($x eq "\n") {
			# fall out of that section of Report
			last;
		}
		
	    @chunks = split(' ', $x);  # matches any whitespace
		if ($chunks[5] > 0) {
			# must have non-zero service demand to get hashed
			push(@{$nodekv{$chunks[2]}}, $chunks[3]);
		}
	}
}

close(INFILE) or die "can't close $infile: $!";

# diagnostics
#print "Chunks: @chunks\n";
print Dumper(\%nodekv);







