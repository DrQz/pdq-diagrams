#! /usr/bin/perl -w
#
# Extract PDQ nodes and streams from Report file and emit a GV dot file.
# Using PDQ 7.0.0 and GV 2.36 (2.36.0)
# Created by NJG on Tuesday, December 05, 2017
#
# Version 1: Use nodes as keys and streams as values
# Version 2: Use streams as keys and nodes as values
# Version 3: Hash PDQ node types to select GV image

use strict;
use Data::Dumper;

########################
# Read Report keywords 
########################
my $filename = $ARGV[0];
if (not defined $filename) {
	die "Usage: pdqx.pl base filename\n";
}

my $infile = "$filename-rpt.txt";
open(INFILE, "< $infile") or die "Can't open $infile: $!";

# Globals
my $openqnm = 1;
my $started = 0;
my %streamKV; # hash of arrays of nodes
my %nodetype; # hash of node types

while (<INFILE>) {
	my $x = $_;
	
	# Keyword pattern
	if ($x =~ m/Node|Sched|Resource|Workload|Class|Demand/ and !$started) {
		$started = 1;
		next; 
	}
	
	if ($started) {		
		if ($x =~  /---/) {
		    # skip heads and underline
			next; 
		}
		
		if ($x =~ m/Queueing|Circuit|Totals/) {
			# end of WORKLOAD Parameters section
			last;
		}
		
		# parse the current line
	    my @fields = split(' ', $x);  # matches any whitespace
	    if ($fields[4] eq "Closed") {
	    	$openqnm = 0; # initialized true
	    }
	    
	    if ($fields[5] > 0) {
	    	# node must have non-zero demand for work to get its name
	    	push(@{$streamKV{$fields[3]}}, $fields[2]);
	    }
	    
	    # Need PDQ node type to select queue image
	    if ($fields[2]) { # valid node name
	    	$nodetype{$fields[2]} = $fields[1];
	    }
	}
}

close(INFILE) or die "Can't close $infile: $!";

# Diagnostics
print Dumper(\%nodetype);
print Dumper(\%streamKV);


########################
# Emit GV format
########################
my $dot = "$filename.dot";
open(DOT, "> $dot") or die "Can't open $dot: $!";

# Start GV block
my $datestring = localtime();
print DOT "/* Generated by pdqx.pl on $datestring */\n";
print DOT "/* Performance Dynamics Company, www.perfdynamics.com */\n";
print DOT "digraph G {\n";
print DOT "\tgraph [shape=none,label=\"PDQX of \'$filename\' model on $datestring\",labelloc=b,fontsize=18,fontcolor=gray];\n";
print DOT "\tsize=\"11,8\";\n";
print DOT "\tcompound=true;\n";
print DOT "\tranksep=1.0;\n";
print DOT "\trankdir=LR;\n" if $openqnm;
print DOT "\tnode [shape=plaintext, fontsize=16, label=\"\"];\n";

# PDQ stream source-sink nodes
my $len_max = 0;

# Get longest list of streams
for my $key ( keys %streamKV ) {
	my $len = $#{ $streamKV{$key} } + 1;
	if ($len > $len_max) {
		$len_max = $len;
	}
}

# Define sources/sinks
if ($openqnm) {
	for my $key (keys %streamKV) {
		print DOT "\tsrc_" .  "$key" . "[label=$key];\n";
		print DOT "\tsnk_" .  "$key" . "[label=$key];\n";
	}
} else { #closedqnm
	for my $key (keys %streamKV) {
		print DOT "\tterm_" . "$key [shape=none, label=$key, image=\"images/node-delay.png\"];\n";
	}
}

# Define queueing nodes
for my $key (keys %streamKV) { # stream
	foreach (@{$streamKV{$key}}) { # listed node 
		if ($nodetype{$_} eq "MSQ") {
			print DOT "\t$_ [shape=none, label=$_, image=\"images/node-multi.png\"];\n";
		} else {
			print DOT "\t$_ [shape=none, label=$_, image=\"images/node-single.png\"];\n";
		}
	}
}

# Define arcs between node pairs
for my $key (keys %streamKV) { # stream
	if ($openqnm) {
		print DOT "\tsrc_$key -> ";
	} else { #closedqnm
		print DOT "\tterm_$key -> ";
	}
	foreach (@{$streamKV{$key}}) { # listed node 
		print DOT "$_";
		print DOT " -> ";
	}
	if ($openqnm) {
		print DOT "snk_$key;";
	} else { #closedqnm
		print DOT "term_$key;" ;
	}
	print DOT "\n";
}

if (not $openqnm) {
	for my $key (keys %streamKV) { # stream 
		print DOT "\t{rank=same; ";
		foreach (@{$streamKV{$key}}) { # node
			print DOT "$_; ";
		}
		print DOT "}\n";
	}
}

# End GV block
print DOT "}\n";

close(DOT) or die "Can't close $dot: $!";
