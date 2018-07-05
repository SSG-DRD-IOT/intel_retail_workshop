# UpdateDelimiters.pl
# - Replaces all instances of commas - used as delimiters in metadata.csv and hierarchy.csv with pipes - |
# Last Updated Date: 01/16/2014
# - To include checking of filenames in hierarchy.csv/hierarchy_temp.csv for whitespace, parentheses and character entities

use strict;
use warnings;

print STDERR "*********************************************************************\n";
print STDERR "Updating the delimiters in metadata.csv and hierachy.csv \n";
print STDERR "*********************************************************************\n";
print STDERR "\n";

# ---------------------------------------------------------------------
# Replace commas with | in "metadata.csv"
print STDERR "* Processing metadata.csv\n";
print STDERR "  - Created metadata_temp.csv\n";
print "\n";

open (METAFILE, "<", "../idz/metadata.csv") || warn ("Cannot open file metadata.csv: $!\n");
open (METAFILETMP, ">", "../idz/metadata_temp.csv") || warn ("Cannot open file meta-tmp.csv: $!\n");

while (<METAFILE>) {
	#chomp;
	#

	#s/(field),(value)\n/$1\|$2\n/g;
	#s/(title),(.+)\n/$1\|$2\n/g;
	#s/(intelswd-\w+),(.+)/$1\|$2\n/g;

	s/(field),(value)/$1\|$2/g;
	s/(title),(.+)/$1\|$2/g;
	s/(intelswd-\w+),(.+)/$1\|$2/g;
	#s/(intelswd-\w+),\n/$1\|\n/g;
	s/(intelswd-\w+),\n//g;

	print METAFILETMP "$_";
	#print STDERR "$_";
}
close(METAFILE);
close(METAFILETMP);

#rename("metadata_temp.csv","metadata.csv");

# ---------------------------------------------------------------------
# Replace commas with | in "hierarchy.csv"
print STDERR "* Processing hierarchy.csv\n";
print STDERR "  - Created hierarchy_temp.csv\n";
print "\n";

open (HIERARCHYFILE, "<", "../idz/hierarchy.csv") || warn ("Cannot open file hierarchy.csv: $!\n");
open (HIERARCHYFILETMP, ">", "../idz/hierarchy_temp.csv") || warn ("Cannot open file hierarchy-tmp: $!\n");

while (<HIERARCHYFILE>) {
	#chomp;
	#

	#s/(level),(uuid),(title),(filename)\n/$1\|$2\|$3\|$4\n/g;
	#s/([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w),(.+\.html?)\n/$1\|$2\|$3\|$4\n/g;
	s/^(level),(uuid),(title),(filename)/$1\|$2\|$3\|$4/g;
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?)/$1\|$2\|$3\|$4/g;
	s/,,,\n/\n/g;
	s/,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),,(.+\w\w\w\w?)/\|$1\|\|$2/g;
	s/(\|)\"/$1/g;
	s/\"(\|)/$1/g;

	s/\&\#x0002C\; /, /g;

	print HIERARCHYFILETMP "$_";
	#print STDERR "$_";
}
close(HIERARCHYFILE);
close(HIERARCHYFILETMP);

#rename("hierarchy_temp.csv","hierarchy.csv");

open (HIERARCHYFILETMP, "<", "../idz/hierarchy_temp.csv") || warn ("Cannot open file hierarchy-tmp: $!\n");

while (<HIERARCHYFILETMP>) {
	if (/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|.+\|.+\|$/) {
		print STDERR "Delimiter error in hierarchy_temp.csv. \nPlease correct in hierarchy.csv:\n";
		print STDERR "   $_";
	}
	if (/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|.+\|.+ /) {
		print STDERR "Whitespaces found in filename in hierarchy_temp.csv. \nPlease correct in hierarchy.csv and update any related links!\n";
		print STDERR "   $_";
	}
	if (/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|.+\|.+(\(|\))/) {
		print STDERR "Parentheses found in filename in hierarchy_temp.csv. \nPlease correct in hierarchy.csv and update any related links!\n";
		print STDERR "   $_";
	}
	if (/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|.+\|.+&\#/) {
		print STDERR "Character entity found in filename in hierarchy_temp.csv. \nPlease correct in hierarchy.csv and update any related links:\n";
		print STDERR "   $_";
	}
}
close(HIERARCHYFILETMP);

# ---------------------------------------------------------------------
print STDERR "Processing Complete!\n";
print STDERR "*********************************************************************\n\n";
