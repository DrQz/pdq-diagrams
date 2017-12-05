#! /usr/bin/perl -w
#
# Update version string in PDQ_Lib.h
# This script is ignored by CVS by being named in .cvsignore
# Created by NJG on Wednesday, August 19, 2015

#use strict;
use POSIX qw(strftime);

# Set PDQ version numbers: maj.min.rev
$maj = 6; # major
$min = 2; # minor
$rev = 0; # revision

# Produce compact date string, e.g., 081915
$date = strftime("%m%d%y", localtime);
$newstring = "static char *version = \"PDQ Analyzer $maj.$min.$rev $date\"";
#print("New string: $newstring\n");


# open file PDQ_Lib.h and scan for line
# static char *version = "PDQ Analyzer 6.1.2 081815";

my $keywords = quotemeta "static char *version";
#open(FILE, "<PDQ_Lib.h");
#my @lines = <FILE>;
#print("Line that matched: \"$keywords\"\n");
#for (@lines) {
#    if ($_ =~ /$keywords/) {
#    	my $x = $_;
#    	print("Old string: ", $x);
#    	#$_ =~ s/$x/$newstring/;
#        print("New string: ", $newstring, "\n");
#    }
#}
#close(FILE);

# In general, there's no direct way for Perl to seek to a particular line of a
# file, insert text into a file, or remove text from a file.
# http://goo.gl/Y5o7pW

my $file = "PDQ_Lib.h";
my $old = "$file";
my $new = "$file.tmp";
my $bak = "$file.bak";
open(OLD, "< $old")         or die "can't open $old: $!";
open(NEW, "> $new")         or die "can't open $new: $!";

while (<OLD>) {
	if ($_ =~ /$keywords/) { 
	my $x = $_;
	s/$x/$newstring/ee 
	};
	(print NEW $_)          or die "can't write to $new: $!";
}

close(OLD)                  or die "can't close $old: $!";
close(NEW)                  or die "can't close $new: $!";
rename($old, $bak)          or die "can't rename $old to $bak: $!";
rename($new, $old)          or die "can't rename $new to $old: $!";




