# ProcessHHK.pl 
# - Takes a .hhk file as input and strips out all content except for titles and HTML filenames
# - Generates a "toc.txt" file as output
# - Formats the output using pipes (|) so that the resulting "toc.txt" file can be imported into MS Excel
# Peter Shepton. 

# Last Updated Date: 09/10/2013

use strict;
use warnings;

my $input_hhc = shift @ARGV;

#$/ = "";

print STDERR "* Processing content from $input_hhc\n";
print "\n";

open (HHCFILE, "<", $input_hhc) || warn ("Cannot open file $input_hhc: $!\n");
open (TOCFILE, ">", "toc.txt") || warn ("Cannot open file toc.txt: $!\n");

#print TOCFILE "level|uuid|title|filename";

while (<HHCFILE>) {
	chomp;

	s/<\?xml version=\"[0-9]+\.[0-9]+\" encoding=\"utf-8\"\?>//g;
	
	# MS HTML Help .hhc
	s/<\!-- \w+ [0-9]+\.[0-9]+ -->//g;
	s/(\W+)<param name=\"Name\" value=\"(.+)\">/\n$1\|\|$2\|/g;
	s/\W+<param name=\"Local\" value=\"(.+\.html?)\">/$1/g;
	s/\W+<param name=\"Local\" value=\"(.+\.html?)\#.+\">/$1/g;
	s/\W+<param name=\"Local\" value="(.+\.pdf)\">/RESOLVE LINK TO PDF!!: $1/g;
	s/\W+<param name=\"x-condition\" value=\"\w+\">//g;
	s/\W+<param name=\"\w+\W?\w+\" value=\"\w+\W?\w+\">//g;	
	s/\W+<param name=\"Font\" value=\"\w+,[0-9]+,[0-9]+\">//g;
	s/<object type=\"\w+\/\w+\s?\w+\">//g;

	# RoboHelp .hhc
	s/<toc version=\"[0-9]+\.[0-9]+\">//g;
	#s/\W+<properties \w+=\"\w+\" \w+=\"\w+\" \w+=\"\w+\">//g;
	#s/\W+<properties \w+=\"\w+\" \w+=\"\w+\">//g;
	#s/\W+<properties \w+=\"\w+\">//g;
	s/\W+<properties .+>//g;
	s/(\W+)<item name=\"/\n$1\|\|/g;
	s/\" link=\"(.+.html?)\">/\|$1/g;
	s/\" link=\"(.+.html?)\#.+\">/\|$1/g;
	s/\" link=\"(.+.html?)\" x-condition=\".+\">/\|$1/g;
	s/\" x-condition=\".+\">/\|/g;
	s/\">/\|/g;
	
	s/\W+<\/?\w+>//g;
	s/<\/?\w+>//g;

	print TOCFILE "$_";
	#print STDERR "$_";
}
close(TOCFILE);
close(HHCFILE);

open (TOCFILE, "<", "toc.txt") || warn ("Cannot open file toc.txt: $!\n");
open (TEMPTOCFILE, ">", "temptoc.txt") || warn ("Cannot open file temptoc.txt: $!\n");

while (<TOCFILE>) {
	#chomp;

	s/\|$/\|!!!EMPTY HEADER - NO ACCOMPANYING HTML FILE!!!/g;
	
	print TEMPTOCFILE "$_";
	#print STDERR "$_";
}
close(TEMPTOCFILE);
close(TOCFILE);

rename("temptoc.txt","toc.txt");

print STDERR "* Processing complete!\n";
print STDERR "  - file \"toc.txt\" created.\n";
