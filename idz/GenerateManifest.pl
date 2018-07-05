# GenerateManifest.pl
# - Generates a document bundle manifest file "intel-swd-manifest.xml"
#   from two .csv files - metadata_temp.csv.csv and hierarchy_temp.csv.csv
# - Creates a copy of all HTML files referenced in the hierarchy.csv file with corresponding UUID
#   filenames - which are also specified in the hierarchy.csv file.
#   The new UUID files are placed in a sub-folder "document_bundle"
# - Updates all HTML file and image links in the newly-created UUID-named HTML files- replacing
#   original filenames with UUID filenames.
# - Zips up the all the UUID-named HTML and image files in the sub-folder "document_bundle" as
#   "document_bundle.zip" - ready for import into IDZ.
# - In the step that updates filenames with their UUID equivalents, I updated all regular
#   expression matches and substitutions to be case-insensitive. Updated 4-27-2016.
# - 05/20/2016: FF added support for bmp images

# Last Updated Date: 05/20/2016

use Archive::Zip qw( :ERROR_CODES );
use Cwd;
use Cwd 'abs_path';
use File::Copy qw(copy);
use File::Find;
use strict;
use warnings;
use XML::Parser;
use XML::LibXSLT;
use XML::LibXML;
use File::Spec; # CQDPD200375725 FF: Fix support for UUID replacement of relative paths to files

#@ARGV = ('.') unless @ARGV;
#my $dir = shift @ARGV;

# CQDPD200375725 FF: Fix support for UUID replacement of relative paths to files
my $META_TEMP_FILENAME = "..//idz//metadata_temp.csv";

print STDERR "*********************************************************************\n";
print STDERR "\n";
print STDERR "* Remove 'document_bundle' directory if it exists\n";
print STDERR "\n";
if (-d "document_bundle") {
    File::Path->remove_tree('document_bundle');
}

print STDERR "*********************************************************************\n";
print STDERR "Generating Non-IPIX Bundle Manifest File\n";
print STDERR "*********************************************************************\n";
print STDERR "\n";

#open (LOGFILE, ">", "logfile.txt") || warn ("Cannot open file logfile.txt: $!\n");

# ---------------------------------------------------------------------
# Get content from "metadata_temp.csv" and output to "intel-swd-manifest.xml"
print STDERR "* Processing metadata_temp.csv\n";
print "\n";

open (METAFILE, "< ", "$META_TEMP_FILENAME") || warn ("Cannot open file metadata_temp.csv: $!\n");
open (MANIFESTFILE, "> ", "..//idz//intel-swd-manifest.xml") || warn ("Cannot open file intel-swd-manifest.xml: $!\n");

while (<METAFILE>) {
	#chomp;
	#

	s/^field\|value/<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<intel-swd-manifest>\n<intel-swd-metadata>\n/g;
	s/^(title)\|(.+)//g;
	s/^(intelswd.\w+)\|(.+)/<$1 value=\"$2\"\/>\n/g;
	s/^(intelswd.\w+)\|$/<$1 value=\"\"\/>/g;
	s/(<intelswd.author value=\".+\"\/>)/$1\n<\/intel-swd-metadata>/g;
	print MANIFESTFILE "$_";
	#print STDERR "$_";
}
close(METAFILE);

# ---------------------------------------------------------------------
# Get content from "hierarchy_temp.csv" and output to "intel-swd-manifest.xml"
print STDERR "* Processing hierarchy_temp.csv\n";
print "\n";

open (HIERARCHYFILE, "< ", "..//idz//hierarchy_temp.csv") || warn ("Cannot open file hierarchy_temp.csv: $!\n");
open (MANIFESTFILE, "+>> ", "..//idz//intel-swd-manifest.xml") || warn ("Cannot open file intel-swd-manifest.xml: $!\n");

# initialize weight counter
my $weightcounter=1;

# CQDPD200253879 FF: Initialize column flag for hierarchy.csv
my $flag_columnsfound = 0;

while (<HIERARCHYFILE>) {
	#chomp;
	#

	# CQDPD200253879 FF: Strip column names if found
	if ($_ =~ m/^level\|uuid\|title\|filename\n?/gi) {
	    s/^level\|uuid\|title\|filename\n?//gi;
	    $flag_columnsfound = 1;
	}

	s/^\n//g;
	s/\|\|\|\n?//g;

	# Replace special characters to avoid XSL issues
	s/®/\(R\)/g;
	s//\(TM\)/g;
	s/©/\(C\)/g;
	s/</\[lt\]/g;
	s/>/\[gt\]/g;
	s/\&gt\;/\[gt\]/g;

	# Substitute original HTML filename (including any path info) with UUID
	$weightcounter++ if s/([0-9]+)\|(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})\|(.+)\|((.+)(\.html?))/<intel-swd-topic weight=\"$weightcounter\" filename=\"$2$6\" id=\"$2\" title=\"$3\" hierarchy-level=\"$1\" parent-id=\"\" hierarchy-path=\"\"\/>\n/g;

	# Substitute original image filename (including any path info) with UUID
	s/^\|(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})\|\|.+(\.[A-Za-z][A-Za-z][A-Za-z])/<intel-swd-image>$1$2<\/intel-swd-image>\n/g;

	# Remove \\ escape characters for parentheses
	s/\\\(/\(/g;
	s/\\\)/\)/g;

	print MANIFESTFILE "$_";
	#print STDERR "$_";
}

print MANIFESTFILE "</intel-swd-manifest>\n";
close(HIERARCHYFILE);
close(MANIFESTFILE);

# CQDPD200253879 FF: If hierarchy.csv column names were not replaced, die.
if (!$flag_columnsfound) {
    die("ERROR! File 'hierarchy.csv' contains incorrect column names.\nColumn names must be: 'level', 'uuid', 'title' and 'filename'.\n\nProcessing stopped!\n\n");
}

#copy("intel-swd-manifest.xml","temp-manifest.xml") or die "Copy failed for tmp.xml to temp-manifest.xml: $! ";

# ---------------------------------------------------------------------
# initialize parser object and parse the string
my $parser = XML::Parser->new( ErrorContext => 2 );
eval { $parser->parsefile('intel-swd-manifest.xml'); };

print STDERR "* Generating Manifest File\n";

# ---------------------------------------------------------------------
# Using XSL add nesting structure to <intel-sw-topic> elements so that
# parent ID and hierarchy path info can be added
XML::LibXSLT->max_depth(1000);

my $XML_FILENAME = "..//idz//intel-swd-manifest.xml";
my $XSL_FILENAME = ".//genNonIPIXBundleAddStructure.xsl";
my $XSL_OUTPUT = "tmp.xml";

# Create XSLT object
my $xslt = XML::LibXSLT->new() || die "Failed to create xmlparser";
my $stylesheet = $xslt->parse_stylesheet_file($XSL_FILENAME);
my $results    = $stylesheet->transform_file($XML_FILENAME);

# Output transformed XML to $XSL_OUTPUT
print $stylesheet->output_file($results,$XSL_OUTPUT);

#copy("tmp.xml","temp-manifest2.xml") or die "Copy failed for tmp.xml to temp-manifest2.xml: $! ";

rename("tmp.xml","intel-swd-manifest.xml");


# ---------------------------------------------------------------------
# Using XSL add parent ID and hierarchy-path attribute values
$XML_FILENAME = "intel-swd-manifest.xml";
$XSL_FILENAME = "./genNonIPIXBundleAddPI-HP.xsl";
$XSL_OUTPUT = "tmp.xml";

# Create XSLT object
$xslt = XML::LibXSLT->new() || die "Failed to create xmlparser";
$stylesheet = $xslt->parse_stylesheet_file($XSL_FILENAME);
$results    = $stylesheet->transform_file($XML_FILENAME);

# Output transformed XML to $XSL_OUTPUT
print $stylesheet->output_file($results,$XSL_OUTPUT);

#copy("tmp.xml","temp-manifest3.xml") or die "Copy failed for tmp.xml to temp-manifest3.xml: $! ";

rename("tmp.xml","intel-swd-manifest.xml");


# ---------------------------------------------------------------------
# Remove <intel-swd-topic> element nesting plus insert HTML special character entities
open (MANIFESTFILE, "< ", "intel-swd-manifest.xml") || warn ("Cannot open file intel-swd-manifest.xml: $!\n");
open (MANIFESTFILETMP, "+>> ", "tmp.xml") || warn ("Cannot open file tmp.xml: $!\n");

while (<MANIFESTFILE>) {

	s/(<intel-swd-topic .+")>/$1\/>/g;
	s/<\/intel-swd-topic>\n?//g;
	s/></>\n</g;
	s/^ +//g;
	#s/( id=\").+\\(.+\" title=\")/$1$2/g;

 	print MANIFESTFILETMP "$_";
#	print STDERR "$_";
}

close(MANIFESTFILE);
close(MANIFESTFILETMP);

rename("tmp.xml","intel-swd-manifest.xml");

print STDERR "  - Manifest File generation completed!\n";
print "\n";


# ---------------------------------------------------------------------
# initialize parser object and parse the string
eval { $parser->parsefile('intel-swd-manifest.xml'); };

# ---------------------------------------------------------------------
# Collect UUIDs and HTML/image filenames from file "hierarchy_temp.csv"

print STDERR "* Collecting UUID and HTML/image filenames from hierarchy_temp.csv file.\n";
#print LOGFILE "\n*******************************************************************\n";
#print LOGFILE "* Collecting UUID and HTML/image filenames from hierarchy_temp.csv file.\n";


open (HIERARCHYFILE, "< ", "..//idz//hierarchy_temp.csv") || warn ("Cannot open file hierarchy_temp.csv: $!\n");

my %mapFileList = ();
my %mapFileStemList = ();
my %mapImgFileList = ();
my %mapImgFileStemList = ();
my $origFile;
my $origFileFullPath;
my $origFileStem;
my $origImgFile;
my $uuidFile;
my $uuidFileStem;
my $uuidImgFile;

# CQDPD200375725 FF: Fix support for UUID replacement of relative paths to files
# Record whether backslash or slash was used in hierarchy.csv
my $Found_Slash = 0;

while (<HIERARCHYFILE>) {
	if (/(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}).+\|((.+)(\.\w\w\w\w?))/) {
		$uuidFile = $1.$4;
		$uuidFileStem = $1;
		$origFile = $2;
		$origFileStem = $3;

        # CQDPD200375725 FF: Fix support for UUID replacement of relative paths to files
        # Record whether backslash or slash was used in hierarchy.csv
        if (!$Found_Slash) {
            if ($origFileStem =~ /\//) {
                $Found_Slash = 1;
            }
            if ($origFileStem =~ /\\/) {
                $Found_Slash = 2;
            }
        }

        # Create hash arrays for HTML files
		if ($origFile =~ m/\.html?/) {
			# Add attribute value as key and content as value in hash array
			# hash array for full filename
			$mapFileList{$origFile} = $uuidFile;
			# hash array for filenames without extension
			$mapFileStemList{$origFileStem} = $uuidFileStem;
#			print LOGFILE "$origFileStem: $uuidFileStem\n";
		}
		# Create hash arrays for image files
		else {
			# Add attribute value as key and content as value in hash array
			# hash array for full filename
			$mapImgFileList{$origFile} = $uuidFile;
		}
	}
}
close(HIERARCHYFILE);

# Test that hash array has been loaded correctly
#print STDERR "Collect uuids and filenames.\n";
#foreach $origFile (keys (%mapFileList)) {
#		print STDERR "$origFile: $mapFileList{$origFile}\n";
#}
#print STDERR "\# ---------------------------------------------------------------------\n";
#foreach $origFileStem (keys (%mapFileStemList)) {
#		print STDERR "$origFileStem: $mapFileStemList{$origFileStem}\n";
#}
#print STDERR "\# ---------------------------------------------------------------------\n";
#print "\n";
#foreach $origFile (keys (%mapImgFileList)) {
#		print STDERR "$origFile: $mapImgFileList{$origFile}\n";
#}
#print STDERR "\# ---------------------------------------------------------------------\n";
#print "\n";

print STDERR "  - UUID and filename collection completed!\n";
print "\n";

# ---------------------------------------------------------------------
# Open "intel-swd-manifest.xml" and replace any special characters with
# Unicode character entities
print STDERR "* Updating manifest file - inserting Unicode character entities.\n";

open (MANIFESTFILE, "+<", "intel-swd-manifest.xml") || warn ("Cannot open file intel-swd-manifest.xml: $!\n");
open (MANIFESTFILETMP, "+>>", "tmp.xml") || warn ("Cannot open file tmp.xml: $!\n");
my $intelswdID;

# Replace text special characters with Unicode character entities
while (<MANIFESTFILE>) {
	# Store intelswd-id metadata value to be inserted later into
	# <meta name="root-id" content="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"/> tag in each HTML file
	if (/intelswd.id value=\"(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})\"/) {
		$intelswdID = $1;
	}

	s/\(R\)/\&\#x00AE\;/g;
	s/\(TM\)/\&\#x2122\;/g;
	s/\(C\)/\&\#x00A9\;/g;
	s/\[lt\]/\&lt\;/g;
	s/\[gt\]/\&gt\;/g;
	print MANIFESTFILETMP "$_";
}

close(MANIFESTFILE);
close(MANIFESTFILETMP);

print STDERR "  - Manifest File update completed!\n";
print "\n";

rename("tmp.xml","intel-swd-manifest.xml");

# ---------------------------------------------------------------------
# Replace all instances of original filenames with corresponding UUIDs
# in HTML files
print STDERR "* Updating HTML and image filenames with UUID filenames.\n";

my $docBundle = "document_bundle";
unless(-e $docBundle or mkdir $docBundle) {
	die "Unable to create directory: $docBundle\n";
}
my $docBundleFullPath = abs_path($docBundle);
my $uuidFileName;
my $movedUUIDFileName;

print STDERR "  - Updating HTML filenames with UUID filenames.\n";

#print LOGFILE "\n*******************************************************************\n";
#print LOGFILE "  - Updating HTML filenames with UUID filenames.\n";

# Process HTML files
foreach $origFile (keys (%mapFileList)) {

	$uuidFile = $mapFileList{$origFile};
	# If origFile contains parentheses - remove \\ escape characters
	$origFile =~ s/(.+)\\\((.+)\\\)(.+)/$1\($2\)$3/gi;
#	print LOGFILE "Processing \"$origFile\" into \"$uuidFile\"\n";

	open (ORIGFILE, "+<:encoding(utf8)", $origFile) || warn ("    * ERROR - Cannot open file $origFile: $!\n      Check hierarchy.csv and intel-swd-manifest.xml and ensure that the filename/path is correct.");
	# Open UUID file for output
	#open (UUIDFILE, "+>>", $uuidFile) || warn ("Cannot open file $uuidFile $!\n");
	open (UUIDFILE, ">:encoding(utf8)", $uuidFile) || warn ("Cannot open file $uuidFile $!\n");
	# Insert <?xml version="1.0" encoding="UTF-8"?>
	print UUIDFILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	#print STDERR "Processing $origFile\n";
    my $headTagFound = 0;
	while (<ORIGFILE>) {

		# Insert <meta> tag named root-id within <head> with the @content attribute value derived from the intelswd-id metadata value
		if ($_ =~ /<head.+/i) {
            s/(<head.+)/$1\n<meta name=\"root-id\" content=\"$intelswdID\"\/>/i;
            $headTagFound = 1;
        }

		# Insert <meta> tag named keywords within <head> - Optional - Used for search engine optimization
		#
		# Insert <div> to wrap all <body> content
		my ($uuidFileID) = $uuidFile =~ m/(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})/i;
        s/(<body.+)/$1\n<div class=\"topic-wrapper\" id=\"$uuidFileID\">/i;
		s/(<\/body>)/<\/div>\n$1/i;

		# CQDPD200375725 FF: Fix support for UUID replacement of relative paths to files
		# Process html references
        my @matches = (m/href=\"([a-zA-Z#_\-=\w\.\/]+)(\.html?)/gi);
        my $num_matches = scalar @matches;
        for ( my $i = 0; $i < $num_matches; $i+=2) {
            # Put together the href contents
            my $filename = $matches[$i];
            my $extension = $matches[$i+1]; # Extension has leading .
            my $href_content = $filename.$extension;

            # Process the href content to become relative to the root directory
            my $relative_href = resolve_to_root($href_content, $origFile);

            # Strip .html? extension
            $relative_href =~ s/\.html?//i;

            # Use the relative_href as a key into hash %mapFileStemList to get the UUID
            my $uuid = $mapFileStemList{$relative_href};
            if (defined($uuid)) {
                # Replace the href contents with the uuid
                s/href=\"$filename(\.html?)/href=\"$uuid$1/gi;
            } else {
                # Warn. This href was not updated because a match was not found in the hash
                print STDERR "\nWarning: An HTML reference was found but could not be updated with a UUID because a mapping doesn't exist in hierarchy.csv.";
                print STDERR "\nHTML reference: $relative_href\n";
            }
		}

        # CQDPD200375725 FF: Fix support for UUID replacement of relative paths to files
        # Process image references
		my @img_matches = (m/src=\"([a-zA-Z#_\-=\w\/\\]+)(\.)(jpg|JPG|png|PNG|gif|GIF|bmp|BMP)\"/gi);
        my $num_img_matches = scalar @img_matches;
        for ( my $i = 0; $i < $num_img_matches; $i+=3) {
            # Put together the href contents
            my $filename_noext = $img_matches[$i];
            my $extension = $img_matches[$i+2]; # Extension does NOT have leading .
			my $href_content = $filename_noext.'.'.$extension;

            # Process the href_content to become relative to the root directory
            my $relative_href = resolve_to_root($href_content, $origFile);

            # Use the relative_href as a key into hash %mapImgFileList to get the UUID
            my $uuid = $mapImgFileList{$relative_href};
            if (defined($uuid)) {
                # Replace the href contents with the uuid
                s/src=\"$filename_noext\.$extension\"/src=\"$uuid\"/gi;
            } else {
                # Warn. This href was not updated because a match was not found in the hash
                print STDERR "\nWarning: An IMAGE reference was found but could not be updated with a UUID because a mapping doesn't exist in hierarchy.csv.";
                print STDERR "\nIMAGE reference: $relative_href\n";
            }
		}

	print UUIDFILE "$_";
	}
    if ($headTagFound == 0) {
        die "\nERROR! Mising the HTML head tag in file: $origFile\n";
    }
	close(ORIGFILE);
	close(UUIDFILE);

	$uuidFileName = "$uuidFile";
	$movedUUIDFileName = "$docBundle/$uuidFile";
	# Move all processd files to the directory "ProcessedFiles"
	rename($uuidFileName, $movedUUIDFileName) or die "Move $uuidFileName -> $movedUUIDFileName failed: $!";
}

# Process image files
print STDERR "  - Updating image filenames with UUID filenames.\n";

#my $currentdir = getcwd;

# If %mapImgFileList is not empty
if (%mapImgFileList) {
	foreach $origImgFile (keys (%mapImgFileList)) {
		# Locate all images
		if ( -e "$origImgFile") {
			# Copy original image to UUID image in ProcessedFiles directory
			$uuidFile = $mapImgFileList{$origImgFile};
			$uuidFile =~ s/.+\/(.+)/$1/g;
			$movedUUIDFileName = "$docBundleFullPath/$uuidFile";
			#print STDERR "Copying \"$origImgFile\" to \"$movedUUIDFileName\"\n";
			copy($origImgFile,$movedUUIDFileName) or die "Copy failed for $origImgFile to $movedUUIDFileName $!";
			#$origFileFullPath = "$currentdir/$origImgFile";
			#print STDERR "Copying \"$origFileFullPath\" to \"$movedUUIDFileName\"\n";
			#copy($origFileFullPath,$movedUUIDFileName) or die "Copy failed for $origFileFullPath to $movedUUIDFileName $!";
		}
		else {
			print STDERR "     * ERROR: Image file \"$origImgFile\" cannot be found!\n       Check hierarchy.csv and ensure that the filename/path is correct.\n";
			#print STDERR "     * ERROR: Image file \"$origFileFullPath\" cannot be found!\n       Check hierarchy.csv and ensure that the filename/path is correct.\n";
		}
	}
}

print STDERR "  - UUID filename update completed!\n";
print STDERR "\n";

# ---------------------------------------------------------------------
# copy manifest file to "ProcessedFiles" directory
my $manifestfile = "intel-swd-manifest.xml";
$movedUUIDFileName = "$docBundle/$manifestfile";
copy($manifestfile,$movedUUIDFileName) or die "Copy failed for $manifestfile to $movedUUIDFileName: $! ";

# ---------------------------------------------------------------------
# Zip up "ProcessedFile"s directory
print STDERR "* Creating zip file \"$docBundle.zip\"\n";

my $zip = Archive::Zip->new();
my $dir;

unless(-e $docBundle or mkdir $docBundle) {
	die "Unable to create directory: $docBundle\n";
}

# Change directory to $docBundle
chdir $docBundle;
$dir = getcwd();

# Add each file in the $docBundle directory to the zip
find(\&addToZip, $dir);

# Write zip file to disk
if ($zip->writeToFileNamed($docBundle.'.zip') != AZ_OK) {
	print "ERROR - Error in document_bundle zip file creation: $!\n";
}

print STDERR "  - Zip file created!\n";
print STDERR "\n";

print STDERR "*********************************************************************\n";
print STDERR "Processing complete!\n";
print STDERR "*********************************************************************\n";


#close (LOGFILE);

# *********************************************************************
# Add all files to the zip file
sub addToZip() {
	if ( -f ) {
		my $file = $_; # Save the current filename
		$zip->addFile($file) # Add the file to the zip
	}
}
# ************************** End of function **************************
# CQDPD200375725 FF: Fix support for UUID replacement of relative paths to files
# Resolve the href_content to be relative to the metadata csv file in the root directory
sub resolve_to_root {
    my $href_content = shift;
    my $orig_file = shift;

    # Get path of the current file
    my $current_file_path = abs_path($orig_file);
    $current_file_path =~ s/(.*)\/(.*)\.html?/$1\//;
    $current_file_path =~ s/(.*)\\(.*)\.html?/$1\\/;

    # Append @href to it and get canon path
    my $tmp_abs_path = $current_file_path . $href_content;
    my $relative_href = File::Spec->canonpath($tmp_abs_path);

    # Get path to $META_TEMP_FILENAME; quotemeta backslashes all non-"word" characters /[A-Za-z_0-9]/
    my $metaTmpPath = abs_path($META_TEMP_FILENAME);
    $metaTmpPath =~ s/[\w\d\s]+\.csv//;
    $metaTmpPath = quotemeta($metaTmpPath);

    # Strip metaTmpPath from resolved_path
    $relative_href =~ s/$metaTmpPath//;

    # Replace Windows backslash with slash if slash was used in hierarchy.csv
    if ($Found_Slash == 1) {
        $relative_href =~ s/\\/\//g;
    }

    # Return the expanded href content, now relative to the directory where metadata_temp.csv lives
    return $relative_href;
}
# ************************** End of function **************************

# Add S&R to remove //\w+/ from hierarchy-path=""
