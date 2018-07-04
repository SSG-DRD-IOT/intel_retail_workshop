# GenerateHTMLHeaderfile.pl 
# - Takes a file aas a argument containing a list of titles and HTML filesnames in the form:
#    title|filename.html
#    title|filename.html
#    title|filename.html
# and then creates a new HTML file based on the filename and inserts the title text

# Last Updated Date: 09/10/2013

use strict; 
use warnings;

my $input_data = shift @ARGV;

print STDERR "* Processing content from $input_data\n";
print "\n";

open (INPUTFILE, "<", $input_data) || warn ("Cannot open file $input_data $!\n");
#open (NewHTMLFILE, ">", "newHTMLfiles.txt") || warn ("Cannot open file newHTMLfiles.txt: $!\n");
my %titleFiles = ();
my $title;
my $fileName;

while (<INPUTFILE>) {
	if (/(.+)\|(.+)/) {
		$title = $1;
		$fileName = $2; 
		# Create hash arrays for title/HTML files
		$titleFiles{$fileName} = $title;
	}
}

close(INPUTFILE);



foreach $fileName (keys (%titleFiles)) {
	#print STDERR "$fileName - title \"$titleFiles{$fileName}\"\n";
	open (NewHTMLFILE, ">", $fileName) || warn ("Cannot open file $fileName: $!\n");
	print STDERR "Creating $fileName - title \"$titleFiles{$fileName}\"\n";
	print NewHTMLFILE "<!doctype HTML public \"-//W3C//DTD HTML 4.0 Frameset//EN\">\n";
	print NewHTMLFILE "<!-- saved from url=(0014)about:internet -->\n";
	print NewHTMLFILE "<html>\n";
	print NewHTMLFILE "<head>\n";
	print NewHTMLFILE "<title>$titleFiles{$fileName}</title>\n";
	print NewHTMLFILE "</head>\n";
	print NewHTMLFILE "<body/>\n";
	print NewHTMLFILE "</html>\n";	
	close(NewHTMLFILE);
}


print "\n";
print STDERR "* Processing complete!\n";
print "\n";