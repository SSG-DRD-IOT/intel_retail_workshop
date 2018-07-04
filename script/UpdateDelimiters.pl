# UpdateDelimiters.pl 
# - Replaces all instances of commas - used as delimiters in metadata.csv and hierarchy.csv with pipes - |
# - To include checking of filenames in hierarchy.csv/hierarchy_temp.csv for whitespace, parentheses and character entities
# - 02/08/2017: Added support for auto-generated aliases

# Last Updated Date: 02/08/2017


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

open (METAFILE, "<", "metadata.csv") || warn ("Cannot open file metadata.csv: $!\n");
open (METAFILETMP, ">", "metadata_temp.csv") || warn ("Cannot open file meta-tmp.csv: $!\n");

my $generate_alias=0; #Added for alias support
while (<METAFILE>) {
	#chomp;
	#

	#s/(field),(value)\n/$1\|$2\n/g;
	#s/(title),(.+)\n/$1\|$2\n/g;
	#s/(intelswd-\w+),(.+)/$1\|$2\n/g;
    #Added for alias support
	if ($_=~/intelswd\-aliasprefix,(.+)$/g)
	{
	$generate_alias=1;
	}
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

open (HIERARCHYFILE, "<", "hierarchy.csv") || warn ("Cannot open file hierarchy.csv: $!\n");
open (HIERARCHYFILETMP, ">", "hierarchy_temp.csv") || warn ("Cannot open file hierarchy-tmp: $!\n");

while (<HIERARCHYFILE>) {
	#chomp;
	#

	#s/(level),(uuid),(title),(filename)\n/$1\|$2\|$3\|$4\n/g;
	#s/([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w),(.+\.html?)\n/$1\|$2\|$3\|$4\n/g;
	#The alias and DO-NOT-EDIT-final-alias columns may or may not be present
	s/^(level),(uuid),(title),(filename),(alias),(DO-NOT-EDIT-final-alias)/$1\|$2\|$3\|$4\|$5\|$6/g;
	s/^(level),(uuid),(title),(filename),(alias)/$1\|$2\|$3\|$4\|$5/g;
	s/^(level),(uuid),(title),(filename)/$1\|$2\|$3\|$4/g;
	#User-defined alias is not set, final alias is present
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?),,(.+\w?)$/$1\|$2\|$3\|$4\|\|$5/g;
	#Both user-defined alias and final alias are present
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?),(.+\w?),(.+\w?)$/$1\|$2\|$3\|$4\|$5\|$6\n/g;
	#User-defined alias is set, final alias column is present but the value is not set
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?),(.+\w?),$/$1\|$2\|$3\|$4\|$5\|\n/g;
	#User-defined alias and final alias columns are present, but values are not set
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?),,$/$1\|$2\|$3\|$4\|\|\n/g;
	#User-defined alias is set, final alias column is not present (this is the first time aliases are generated)
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?),(.+\w?)$/$1\|$2\|$3\|$4\|$5\n/g;
	#User-defined alias column is present, but the value is not set, final alias column is not present (this is the first time aliases are generated)
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?),$/$1\|$2\|$3\|$4\|\n/g;
	#User-defined alias and final alias columns are not present
	s/^([0-9]+),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(.+\w?),(\w.+\.html?)$/$1\|$2\|$3\|$4/g;
	

	s/,,,,,\n/\n/g;
	s/,,,,\n/\n/g;
	s/,,,\n/\n/g;

	s/,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),,(.+\w\w\w\w?),,/\|$1\|\|$2\|/g;
	s/,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),,(.+\w\w\w\w?),/\|$1\|\|$2\|/g;

	s/,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),,(.+\w\w\w\w?)/\|$1\|\|$2/g;
	if ($generate_alias==0)
	{
	s/(\|)\"/$1/g;
	s/\"(\|)/$1/g;
	}
	s/\&\#x0002C\; /, /g;
	
	print HIERARCHYFILETMP "$_";
	#print STDERR "$_";
}
close(HIERARCHYFILE);
close(HIERARCHYFILETMP);

#rename("hierarchy_temp.csv","hierarchy.csv");

open (HIERARCHYFILETMP, "<", "hierarchy_temp.csv") || warn ("Cannot open file hierarchy-tmp: $!\n");

while (<HIERARCHYFILETMP>) {
	if ((/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|.+\|.+\|$/)&&($generate_alias==0)) {
		print STDERR "Delimiter error in hierarchy_temp.csv. \nPlease correct in hierarchy.csv:\n";
		print STDERR "   $_";
	}
	if (/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|([^\|]+)\|([^\|]+ [^\|]+)\|/) {
		print STDERR "Whitespaces found in filename in hierarchy_temp.csv. \nPlease correct in hierarchy.csv and update any related links!\n";
		print STDERR "   $_";
	}
	if (($generate_alias==0)&&(/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|.+\|.+ /)) {
		print STDERR "Whitespaces found in filename in hierarchy_temp.csv. \nPlease correct in hierarchy.csv and update any related links!\n";
		print STDERR "   $_";
	}
	if ((/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|.+\|.+(\(|\))/)&&($generate_alias==0)) {
		print STDERR "Parentheses found in filename in hierarchy_temp.csv. \nPlease correct in hierarchy.csv and update any related links!\n";
		print STDERR "   $_";
	}
	if (/^[0-9]+\|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\|([^\|]+)\|[^\|]+(\(|\))[^\|]+\|/) {
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
