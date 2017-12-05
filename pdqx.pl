#! /usr/bin/perl -w
#
# Extract PDQ node and stream tokens from PDQ_Report() file.
# Version 2: Use work streams as key and nodes as values
# Created by NJG on Tuesday, December 05, 2017

use strict;
use Data::Dumper;

########################
# Read Workload section of Report
########################
my $keywords = quotemeta "Node Sched Resource   Workload";
my $file = "diskopt";
my $infile = "$file-rpt.txt";
open(INFILE, "< $infile") or die "can't open $infile: $!";

my @fields;
my $started = 0;
my %streamKV; # hash of lists

while (<INFILE>) {
	my $x = $_;
	
	if ($x =~ /$keywords/ && !$started) {
		$started = 1;
		next; 
	}
	
	if ($started) {		
		if ($x =~  /---/) {
		    # skip heads and underline
			next; 
		}
		
		if ($x eq "\n") {
			# end of WORKLOAD Parameters section
			last;
		}
		
	    @fields = split(' ', $x);  # matches any whitespace
		if ($fields[5] > 0) {
			# must have non-zero service demand to get hashed
			push(@{$streamKV{$fields[3]}}, $fields[2]);
		}
	}
}

close(INFILE) or die "can't close $infile: $!";

# Diagnostics
#print "fields: @fields\n";
print Dumper(\%streamKV);

########################
# Emit GV format
########################
my $new = "$file.dot";
open(NEW, "> $new") or die "can't open $new: $!";

# Start GV block
print NEW "digraph G {\n";
print NEW "\tsize=\"11,8\";\n";
print NEW "\tcompound=true;\n";
print NEW "\tranksep=1.0;\n";
print NEW "\trankdir=LR;\n";
print NEW "\tnode [shape=plaintext, fontsize=16, label=\"\"];\n";

# PDQ stream source-sink nodes
my $len_max = 0;

# get longest list of streams
for my $key ( keys %streamKV ) {
	my $len = $#{ $streamKV{$key} } + 1;
	if ($len > $len_max) {
		$len_max = $len;
	}
}

# Define sources/sinks
for my $key (keys %streamKV) {
	#print "\tsrc [label=$key];\n";
	#print "\tsnk [label=$key];\n";
	print NEW "\tsrc_" .  "$key" . "[label=$key];\n";
	print NEW "\tsnk_" .  "$key" . "[label=$key];\n";
}

# Define queueing nodes
for my $key (keys %streamKV) { # stream
	foreach (@{$streamKV{$key}}) { # listed node 
		print NEW "\t$_ [shape=none, label=$_, image=\"node-single.png\"];\n";
	}
}

# Define arcs between node pairs
for my $key (keys %streamKV) { # stream
	print NEW "\tsrc_$key ->";
	foreach (@{$streamKV{$key}}) { # listed node 
		print NEW "\t$_";
		print NEW " ->";
	}
	print NEW "\tsnk_$key;";
	print NEW "\n";
}

# End GV block
print NEW "}\n";

close(NEW) or die "can't close $new: $!";

