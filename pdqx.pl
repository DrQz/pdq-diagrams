#! /usr/bin/perl -w
#
# Extract PDQ nodes and streams from Report file and emit a GV dot file.
# Using PDQ 7.0.0 and Graphviz 2.36 (2.36.0)
# Created by NJG on Tuesday, December 05, 2017
#
# Version 1: Use nodes as keys and streams as values
# Version 2: Use streams as keys and nodes as values
# Version 3: Hash PDQ node types to select GV image

use strict;
use Data::Dumper;

# Globals
my $openqnm = 1;
my $started = 0;
my %streamKV; # hash of arrays of nodes
my %nodetype; # hash of node types


#############################
# Tokenize Report parameters 
#############################
my $filename = $ARGV[0];
if (not defined $filename) {
	die "Usage: pdqx.pl base filename\n";
}

my $infile = "$filename-rpt.txt";
open(INFILE, "< $infile") or die "Can't open $infile: $!";

while (<INFILE>) {
	my $line = $_;
	
	# Keyword pattern
	if ($line =~ m/Node|Sched|Resource|Workload|Class|Demand/ and !$started) {
		# start WORKLOAD section
		$started = 1;
		next; 
	}
	
	if ($started) {		
		if ($line =~  /---/) {
		    # skip heads and underline
			next; 
		}
		
		if ($line =~ m/Queueing|Circuit|Totals/) {
			# end of WORKLOAD section
			$started = 0;
			last; # break out of loop
		}
		
		# tokenize current line
	    my @fields = split(' ', $line);  # matches any whitespace
	    
	    # Since each line (array) is a mix of numbers and names (as strings)
	    # there is ambiguity between fields, e.g., both 'Node' and 'Demand' 
	    # fields are numbers but Perl doesn't distinguish integers.
	    # Therefore, need to reference each @fields entry by its index. 
	    # However, indexing can generate the Perl warning
	    # "Use of uninitialized value $fields[i] ..."
	    # The following if statements suppress that warning.
	    
	    if ($fields[2]) { # valid Resource name
	    	# node type in $fields[1] used to select correct queue image
	    	$nodetype{$fields[2]} = $fields[1];
	    }

		if ($fields[4]) { # valid QNM type
	    	$openqnm = 0 if ($fields[4] eq "Closed"); # initialized true
	    }

	    if ($fields[5]) { # valid service Demand
	    	# node must have non-zero demand for work to get its name
	    	push(@{$streamKV{$fields[3]}}, $fields[2]) if ($fields[5] > 0);
	    }
	}
}

close(INFILE) or die "Can't close $infile: $!";

# Diagnostics
#print Dumper(\%nodetype);
#print Dumper(\%streamKV);


########################
# Emit GV dot format
########################
my $dot = "$filename.dot";
open(DOT, "> $dot") or die "Can't open $dot: $!";

# Start GV block
my $nwrap = 6;
my $datestring = localtime();
print DOT "/* Generated by pdqx.pl on $datestring */\n";
print DOT "/* Performance Dynamics Company, www.perfdynamics.com */\n";
print DOT "digraph G {\n";
print DOT "\tgraph [shape=none,label=\"PDQX of \'$filename\' model on $datestring\",labelloc=b,fontsize=18,fontcolor=gray];\n";
print DOT "\tsize=\"22,16\";\n";
print DOT "\tcompound=true;\n";
print DOT "\tranksep=3.0;\n";
print DOT "\tnode [shape=plaintext, fontsize=16, label=\"\"];\n";

if ($openqnm and (keys %nodetype >= $nwrap)) {
	print DOT "\trankdir=LR;\n";
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

# Wrap after 6 nodes per line using rank=same
my $ncount = 0;
for my $nname (keys %nodetype) { # listed node 
	print DOT "\t{ rank=same; " if ($ncount == 0);
	print DOT "$nname; ";
	if ($ncount++ >= 6) {
		print DOT "}\n";
		$ncount = 0;
		next;
	}
}
print DOT "}\n";


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

# End of GV block
print DOT "}\n";

close(DOT) or die "Can't close $dot: $!";
