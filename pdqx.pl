#! /usr/bin/perl -w
#
# Extract PDQ node and stream tokens from PDQ_Report() file.
# Created by NJG on Monday, December 04, 2017

use strict;
use Data::Dumper;

# open Report file and scan for line containing the following keywords ...
my $keywords = quotemeta "Node Sched Resource   Workload";
my $file = "diskopt";
my $infile = "$file-rpt.txt";
open(INFILE, "< $infile") or die "can't open $infile: $!";

my @chunks;
my $started = 0;
my %nodeKV; # hash of lists


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
			push(@{$nodeKV{$chunks[2]}}, $chunks[3]);
		}
	}
}

close(INFILE) or die "can't close $infile: $!";

# diagnostics
#print "Chunks: @chunks\n";
#print Dumper(\%nodeKV);


# GV format template

my $new = "$file.dot";
open(NEW, "> $new") or die "can't open $new: $!";

print NEW "digraph G {\n";
print NEW "\tcompound=true;\n";
print NEW "\tranksep=1.25;\n";
print NEW "\trankdir=LR;\n";
print NEW "\tnode [shape=plaintext, fontsize=16, label=\"\"];\n";

print NEW "\tsrc [label=\"Source\"];\n";
print NEW "\tsnk [label=\"Sink\"];\n";

for my $key ( keys %nodeKV ) {
    print NEW "\t$key [shape=none, label=\"$key\", image=\"node-single.png\"];\n";
}

for my $key ( keys %nodeKV ) {
    print NEW "\tsrc -> $key;\n";
    print NEW "\t$key -> snk;\n";
}

print NEW "}\n";

close(NEW) or die "can't close $new: $!";

