# **************************************************************************************
# "ValidateIntelSWD" takes the IDZ manifest file, e.g. intel-swd-manifest.xml as its argument: 
#  - Checks that the IDZ manifest file is well-formed 
#  - Checks if HTML files referenced by the IDZ manifest file are present in the current directory
#  - Checks if all image and HTML files referenced by HTML are present in the current directory
#  - 2017Jan11 Checks for duplicate aliases in the manifest file
#  - 2017Jan12 Removed support for Audience taxonomy. "Developers" is no longer an available value and no other values apply at this time.
#              Added support for term identifiers for Subject Matter values.
#  - 2017Feb01 Add check for aliases that are greater than 255 character limit.
#
# Run as:
#         ValidateIntelSWD-HTML.pl intel-swd-manifest.xml
#
# SSG Information Development - Tools Team
# Last Updated: 02/01/2017
# *****************************************************************************

use Cwd;
use File::Find;
use strict; 
use warnings;
use List::MoreUtils 'uniq';
use XML::Parser;
use XML::LibXML;


my %guidArray = ();
my %dup_guidArray = ();
my $duplicatecounter = 0;

my $Guid;
my $GuidFile;
my $manifestfile = shift @ARGV;              # the file to parse - manifest file
sub checkForDuplicateAliases;                # Added for alias support
my $duplicateAliasCounter = 0;               # Added for alias support
my $Manifest_Contains_AliasPrefix = 0;       # Boolean - whether manifest expects automated alias support
my $Alias_Prefix_Value = "";
my $Alias_Prefix_Length = 0;
my $DRUPAL_ALIAS_LIMIT = 255;

# --------------------------------------------------------------------- 
# initialize parser object and parse the string
my $parser = XML::Parser->new( ErrorContext => 2 );
eval { $parser->parsefile( $manifestfile ); };

print STDERR "************************************************\n";
print STDERR "Validating $manifestfile and files referenced in the \n";
print STDERR "document bundle.\n";
print STDERR "\n";

#Open log file
open(LOGFILE, ">ValidateIntelSWD.log");
# Validate that manifest file is well-formed XML 
# report any error that stopped parsing, or announce success
print STDERR "Parsing $manifestfile to check that it is well-formed\n";
print LOGFILE "************************************************\n";
print LOGFILE "Validating $manifestfile and files referenced in the document bundle.\n";
print LOGFILE "------------------------------------------------\n\n";
print LOGFILE "Checking if $manifestfile is well-formed:\n";
print LOGFILE "------------------------------------------------\n";
if( $@ ) {
    $@ =~ s/at \/.*?$//s;               # remove module line number
    print LOGFILE "\nERROR in $manifestfile:\n$@\n";
} else {
    #print STDERR "$manifestfile is well-formed\n";
    print LOGFILE " - $manifestfile is well-formed\n";
}

print LOGFILE "------------------------------------------------\n";
print STDERR "************************\n";
print LOGFILE "\n";

# --------------------------------------------------------------------- 
# Validate metadata in manifest file

print STDERR "Validating metadata in $manifestfile\n";
print LOGFILE "Validate metadata in $manifestfile\n";
print LOGFILE "------------------------------------------------\n";

unless(open (INPUTFILE, "$manifestfile")) {
		print STDERR "Cannot open config file $manifestfile, quitting.\n";
		exit 1;
	}
	
my %swdArray = ();
my $swdMetadataCounter;
my $swdMetadata;
my $swdValue;
#my $swdlocale = "locale";
my $swdlang = "lang";
#my $swddoctype = "doctype";
my $swdid = "id";
my $swdpublish = "publish";
#my $swdimport = "import";
my $swdauthor = "author";
my $swdentitlement = "entitlement";
#my $swdcontentremoved = "contentremoved";

my $hierarchyLevel0;

# CQDPD200357824 Add variables for intelswd-tag validation
my %tagsHash = ();
my $tagsCounter = 0;

# CQDPD200362012 Add variables for intelswd-subjectmatter validation; occurrences 1+ expected
my %subjectMatterHash = ();
my $subjectMatterCounter = 0;

while(<INPUTFILE>) {
	if (/<intelswd-?\.?(\w+) value=\"(.+)\"\/>/) {
		$swdValue = $2;	 
		$swdMetadata = $1;	 
		  	
		$swdArray{$swdMetadata} = $swdValue;
	}
	# CQDPD200357824 The intelswd-tag element occurs 0+ in the manifest. To validate, we need all instances.
  if (/<intelswd-tag value=\"(.+)\"\/>/) {
  	$tagsCounter++;
  	my $tagValue = $1;
  	$tagsHash{$tagsCounter} = $tagValue;
  }
    # CQDPD200362012 The intelswd-subjectmatter element occurs 1+ in the manifest. To validate, we need all instances.
    if (/<intelswd-subjectmatter value=\"(.+)\"\/>/) {
  	    $subjectMatterCounter++;
  	    my $value = $1;
  	    $subjectMatterHash{$subjectMatterCounter} = $value;
    }
	if (/hierarchy-level="0"/) {
		$hierarchyLevel0++;
	}
}
close INPUTFILE;

#foreach $swdMetadata (keys (%swdArray)) {
#	print STDERR "$swdMetadata - $swdArray{$swdMetadata}\n";
#}

# Check default value for intelswd-lang	set to "en"
if (exists $swdArray{$swdlang} and $swdArray{$swdlang} eq "en") {
#	print STDERR "Default value for intelswd-lang is set: $swdArray{$swdlang}.\n";
	print LOGFILE "Default value for intelswd-lang is set: $swdArray{$swdlang}.\n";
	$swdMetadataCounter++;
}
else {
#	print STDERR "Default value for intelswd-lang is not set. It should be \"en\".\n";
	print LOGFILE "***ERROR*** Default value for intelswd-lang is not set correctly. It should be \"en\".\n";
}


# Check default value for intelswd-subjectmatter set to "Product Documentation"
# -	Original metadata intelswd-doctype was changed to intelswd-subjectmatter, to reflect which taxonomy it comes from. 07-26-2013
# - 02-06-2015 Changed number of occurrences to 1+. "Product Documentation" is required; One additional occurrence is for doctype
# - 01-12-2017 Term identifiers are now allowed. 
my $numSubjectMatterEntries = 0;
my $isProductDocFound = 0;
my $isDocTypeFound = 0;
my $doctype = "";
$numSubjectMatterEntries = keys(%subjectMatterHash); # Get the size of the subject matter hash
while ($numSubjectMatterEntries > 0){
    my $entry = $subjectMatterHash{$numSubjectMatterEntries};
    if ( ($entry =~ m/Product Documentation/) or ($entry =~ m/20774/) ) {
        $isProductDocFound = 1;
    }
    if ( ($entry =~ m/Catalog|Code Sample|Cookbook|Getting Started|Tutorial|User Guide|Developer Guide|Developer Reference/) 
          or ($entry =~ m/79004|20780|79005|79497|20783|78151|83039|79003/) ) {
        $isDocTypeFound = 1;
        $doctype = $entry;
    }
    $numSubjectMatterEntries--;
}
if ($isProductDocFound) {
	print LOGFILE "Default value for intelswd-subjectmatter is set: Product Documentation or 20774\n";
	$swdMetadataCounter++;
}
else {
#	print STDERR "Default value for intelswd-doctype is not set. It should be \"Product Documentation\".\n";
	print LOGFILE "***ERROR*** Default value for intelswd-subjectmatter is not set correctly. It should be \"Product Documentation\" or \"20774\".\n";
}
if ($isDocTypeFound) {
    print LOGFILE "Value for doctype (intelswd-subjectmatter) found: $doctype.\n";
}
else {
    print LOGFILE "***WARN*** No valid doctype value was defined in a separate intelswd-subjectmatter entry.\n";
}

# Check that value for "intelswd-id" is not empty
#if (exists $swdArray{$swdid} and $swdArray{$swdid} =~ /^$GUIDtext?\w{8}-\w{4}-\w{4}-\w{4}-\w{12}|^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/) {
if (exists $swdArray{$swdid} and $swdArray{$swdid} =~ /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}|^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/) {
#		print STDERR "intelswd-id is set to $swdArray{$swdid}.\n";
		print LOGFILE "Value for intelswd-id is set to $swdArray{$swdid}.\n";
		$swdMetadataCounter++;
}
else {
#	print STDERR "intelswd-id cannot be empty - it must have a GUID or UUID.\n";
#	print LOGFILE "***ERROR*** Value for intelswd-id cannot be empty - it must have a GUID or UUID, e.g.\n";
	print LOGFILE "***ERROR*** Value for intelswd-id must be a GUID or UUID, e.g.\n";
	print LOGFILE "            - GUID-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX\n";
#	print LOGFILE "            - XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX\n";
	print LOGFILE "              or \n";
	print LOGFILE "            - XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX\n";
	print LOGFILE "            where X is any alphanumeric character\n";
}

# Check that format for "intelswd-publish" is dd-mm-YYYY, where YYYY indicates the year in 4-digits. (e.g. 2013. Full example: 21-06-2013)
if (exists $swdArray{$swdpublish}) {
	if ($swdArray{$swdpublish} =~ /[0-3][0-9]-[0-1][0-9]-[1-9][0-9][0-9][0-9]/) {
#		print STDERR "Value for intelswd-publish has correct format (dd-mm-yyyy): $swdArray{$swdpublish}.\n";
		print LOGFILE "Value for intelswd-publish has correct format (dd-mm-yyyy): $swdArray{$swdpublish}.\n";
		$swdMetadataCounter++;
	}
	else {
#		print STDERR "Date value for intelswd-publish is required in the form (dd-mm-yyyy).\n";
		print LOGFILE "***ERROR*** Date value for intelswd-publish is required in the form (dd-mm-yyyy).\n";
	}
}
else {
#	print STDERR "Value for intelswd-publish is not set - a date value is required in the form (dd-mm-yyyy).\n";
	print LOGFILE "***ERROR*** Value for intelswd-publish is not set - a date value is required in the form (dd-mm-yyyy).\n";
}

# Check that value for "intelswd-author" is not empty plus does not contain a domain prefix, e.g. "amr\" - it should contain one IDSID
if (exists $swdArray{$swdauthor}) {
	if ($swdArray{$swdauthor} =~ /\\/) {
#		print STDERR "***ERROR*** Value for intelswd-author should contain a single IDSID without any domain prefix.\n";
		print LOGFILE "***ERROR*** Value for intelswd-author should contain a single IDSID without any domain prefix.\n";
		$swdMetadataCounter++;
	}
	else {
#		print STDERR "Value for intelswd-author is set: $swdArray{$swdauthor}.\n";
		print LOGFILE "Value for intelswd-author is set: $swdArray{$swdauthor}.\n";
		$swdMetadataCounter++;
	}
}
else {
#	print STDERR "***ERROR*** intelswd-author cannot be empty - it must contain one IDSID.\n";
	print LOGFILE "***ERROR*** intelswd-author cannot be empty - it must contain one IDSID.\n";
}

# Check that the value for "intelswd-entitlement" contains the expression “documentation” or is otherwiswe empty.
# (e.g. “documentation-restricted-beta_forwin-13.1” - the only naming convention requirement is the presence of 
# the word “documentation”)
if (exists $swdArray{$swdentitlement}) {
	if ($swdArray{$swdentitlement} =~ /documentation/) {
#		print STDERR "Value for intelswd-entitlement has a valid value: $swdArray{$swdentitlement}.\n";
		print LOGFILE "Value for intelswd-entitlement has a valid value: $swdArray{$swdentitlement}.\n";
		$swdMetadataCounter++;
	}
	else {
#		print STDERR "Value for intelswd-entitlement, if set, must contain the word \'documentation\'.\n";
		print LOGFILE "***ERROR*** Value for intelswd-entitlement, if set, must contain the word \'documentation\'.\n";
	}
}
else {
#	print STDERR "Value for intelswd-entitlement is not set - which is valid.\n";
	print LOGFILE "Value for intelswd-entitlement is not set - which is valid.\n";
	$swdMetadataCounter++;
}

# CQDPD200357824 Check that intelswd-tag(s) do not contain a comma
my $numTags = 0;
my $isCommaFound = 0;
$numTags = keys(%tagsHash); # Get the size of the tag hash
while ($numTags > 0){
  my $tag = $tagsHash{$numTags};
  if ($tag =~ m/,/) {
  	$isCommaFound = 1;
  	print LOGFILE "***ERROR*** Found comma in intelswd-tag '$tag'. If your intelswd-tag value is defined as a comma-separated-value, break each tag into its own intelswd-tag data element.\n";
  	print STDERR "***ERROR*** Found comma in intelswd-tag '$tag'.\n";
  	print STDERR "            If your intelswd-tag value is defined as a \n";
  	print STDERR "            comma-separated-value, break each tag into \n";
  	print STDERR "            its own intelswd-tag data element. \n";
  }
  $numTags--;
}
if (!$isCommaFound) {
	print LOGFILE "No commas found in intelswd-id values.\n";
	$swdMetadataCounter++;
}

# --------------------------------------------------------------------- 
# Build a hash array containing all the topic GUIDs contained in the manifest file
unless(open (INPUTFILE, "$manifestfile")) {
	print STDERR "Cannot open config file $manifestfile, quitting.\n";
	exit 1;
}

while(<INPUTFILE>) {
	# Extract GUID and Guid file data and add to hash array
	#if (/<intel-swd-topic weight=\"([0-9]+)\" filename=\"(($GUIDtext?\w{8}-\w{4}-\w{4}-\w{4}-\w{12})\.html?)\"/) {
	if (/<intel-swd-topic weight=\"([0-9]+)\" filename=\"((\w{8}-\w{4}-\w{4}-\w{4}-\w{12})\.html?)\"/) {
		#$Guid = $2;
		#$GuidFile = $1;
		$Guid = $3;	 
		$GuidFile = $2;	 

		# Load array guidArray with the GUID as the key and the GUID filename as the value
		$guidArray{$Guid} = $GuidFile;
		# Load array dup_guidArray to allow checking for duplicates
		push @{$dup_guidArray{$Guid}}, $GuidFile;
	} 
}

close INPUTFILE;

#print STDERR "\nDuplicate definitions:\n";
for my $Guid (keys %dup_guidArray) {
	if (scalar @{$dup_guidArray{$Guid}} > 1) {
		for $GuidFile (@{$dup_guidArray{$Guid}}) {
			#print STDERR "$Guid => $GuidFile\n";
			print LOGFILE "Duplicate GUID found for $GuidFile.\n";
		}
		#print STDERR "\n";
		$duplicatecounter++;

	}
}

# If $duplicatecounter is not 0 - duplicates exist - so exit
#print STDERR "\$duplicatecounter: $duplicatecounter\n";
if ($duplicatecounter == 0) {	
	print STDERR "SUCCESS: No duplicate GUIDs found in manifest file\n";
}
else {
	#print STDERR "Duplicate GUID: $Guid => $GuidFile\n";
	print STDERR "***ERROR*** The manifest file contains duplicate GUIDs.\n";
	print STDERR "            Check log file ValidateIntelSWD.log for details\n";
	print STDERR "            Exiting processing due to duplicate GUIDs!\n";
	print LOGFILE "Exiting processing due to duplicate GUIDs!\n";
	exit;
}

# Validate that there is only one (the first) <intel-swd-topic> entry with @hierarchy-level=0.
#print LOGFILE "Running initial checks on <intel-swd-topic> elements in the manifest file\n";
#print LOGFILE "------------------------------------------------\n";
if ($hierarchyLevel0 == 1) {
	print STDERR "SUCCESS: Only one instance found of <intel-swd-topic> \n";
	print STDERR "         containing \@hierarchy-level=0.\n";
	print LOGFILE "\@hierarchy-level: Only one instance found of <intel-swd-topic> containing \@hierarchy-level=0.\n";
}
else {
	print STDERR "***ERROR*** There should be a single instance of <intel-swd-topic> containing \@hierarchy-level=0.\n";
	print STDERR "            Validation checking found $hierarchyLevel0 instances\n";
	print LOGFILE "***ERROR*** There should be a single instance of <intel-swd-topic> containing \@hierarchy-level=0.\n";
	print LOGFILE "            Validation checking found $hierarchyLevel0 instances\n";
}

print LOGFILE "------------------------------------------------\n";
print LOGFILE "\n";

# ---------------------------------------------------------------------
# Test if GUID file exits

my $GUIDFileCounter=0;
my $nonexistingFileCounter=0;

print LOGFILE "Checking if HTML files referenced in the manifest file are present:\n";
print LOGFILE "------------------------------------------------\n";
foreach $Guid (keys (%guidArray)) {
   
	my $GUIDFileName = $guidArray{$Guid};
	# Print GUID filename if it can't be found
	unless (-e $GUIDFileName) {
	 print LOGFILE "*** File $GUIDFileName was not found! ***\n";
	 $nonexistingFileCounter++;
	} 
	# Increment GUID file counter 
 	$GUIDFileCounter++;  
	#print STDERR "Found $GUIDFileName\n";
}

print LOGFILE " - Number of referenced HTML files in the manifest file: $GUIDFileCounter\n";
print LOGFILE " - Number of referenced HTML files not found: $nonexistingFileCounter\n";
print LOGFILE "------------------------------------------------\n";
print LOGFILE "\n";

# ---------------------------------------------------------------------
my $manifestfiledir = getcwd;
#print STDERR "$manifestfiledir\n";
my $href_value_img_counter=0;
my $href_value_img_counter_missing=0;
my $href_value_xml_counter=0;
my $href_value_xml_counter_missing=0;

print LOGFILE "Checking if all referenced image and HTML files are present:\n";

find(\&updateHREF,  $manifestfiledir );
# Grab the alias from the manifest file
my $query = XML::LibXML::XPathExpression->new('//intel-swd-manifest/intel-swd-metadata/intelswd-aliasprefix');
my $tmp_parser = XML::LibXML->new();
my $manifest = $tmp_parser->parse_file($manifestfile) or die "ERROR - Could not parse '$manifestfile': $!\n";
my($node) = $manifest->findnodes($query);
if ($node) {
    my $Alias_Prefix_Value = $node->getAttribute('value');
    if ($Alias_Prefix_Value) {
        $Manifest_Contains_AliasPrefix = 1;
        $Alias_Prefix_Length = length $Alias_Prefix_Value;
    }
}
# Added for alias support
if ($Manifest_Contains_AliasPrefix) {
    checkForDuplicateAliases();
}

print LOGFILE "------------------------------------------------\n";
print LOGFILE " - Number of referenced HTML file links: $href_value_xml_counter\n";
print LOGFILE " - Number of missing referenced HTML file links: $href_value_xml_counter_missing\n";
print LOGFILE " - Number of referenced Image file links: $href_value_img_counter\n";
print LOGFILE " - Number of missing referenced Image file links: $href_value_img_counter_missing\n";
print LOGFILE " - Number of duplicate aliases found: $duplicateAliasCounter\n";
print LOGFILE "------------------------------------------------\n";

print STDERR "\nVALIDATION RESULTS\n";

# If metadata validation is complete without errors ...
if ($swdMetadataCounter == 7) {	
	print STDERR "SUCCESS: Metadata in the manifest file appears valid\n";
}
else {
    print STDERR "***ERROR*** There were problems with the metadata in the manifest file.\n";
    print STDERR "            For details check log file ValidateIntelSWD.log\n";
    #print STDERR "            $swdMetadataCounter/10 metadata were correct.\n";
}

if ($nonexistingFileCounter==0) {
    print STDERR "SUCCESS: All HTML files referenced in the manifest file found.\n";
}
else {
    print STDERR "***ERROR*** $nonexistingFileCounter missing files referenced in the manifest file.\n";
}
if ($href_value_xml_counter_missing==0) {
    # DPD200413054 Fix validation for broken links; Updated text for clarity
    print STDERR "SUCCESS: All HTML files references are working.\n";
}
else {
    # DPD200413054 Fix validation for broken links; Updated text for clarity
    print STDERR "***ERROR*** $href_value_xml_counter_missing html file references are broken!\n";
    print STDERR "       For details check log file ValidateIntelSWD.log\n";
}
if ($href_value_img_counter_missing==0) {
    # DPD200413054 Fix validation for broken links; Updated text for clarity
    print STDERR "SUCCESS: All image file references are working.\n";
}
else {
    # DPD200413054 Fix validation for broken links; Updated text for clarity
    print STDERR "***ERROR*** $href_value_img_counter_missing image file references are broken!\n";
    print STDERR "            For details check log file ValidateIntelSWD.log\n";
}
# Added for alias support
if ($Manifest_Contains_AliasPrefix) {
    if ($duplicateAliasCounter == 0) {
        print STDERR "SUCCESS: No duplicate aliases found.\n";
    } else {
        print STDERR "***ERROR*** $duplicateAliasCounter duplicate aliases found!\n";
        print STDERR "            For details check log file ValidateIntelSWD.log\n";
    }
}

print STDERR "\n";
print STDERR "Processing complete!\n";
print STDERR "************************************************\n";

print LOGFILE "\n";
print LOGFILE "Processing complete!\n";
print LOGFILE "************************************************\n";
close LOGFILE;

# ********************************************************************* 
# Function "updateHREF" opens each .htm file and replaces HTML and image file links with corresponding UUIDs
sub updateHREF() {
	
	if ( -f and /.*(\.html?$)/ ) {
		#print STDERR "File name is $_\n\t\tFull path is $File::Find::name\n";
		my $href_value_src_img;
		my $href_value_img_ext;
		my $href_value_xml_ext;
		my $file = $_;
				
		# Enable multi-line edits
		undef $/;
		
		#print STDERR "$file\n";
		
		# Open the file for reading
		open(A,$file);

		# For each line in A i.e. as long as you are in A, line by line
		while(<A>) {
			chomp;
			# Search for all href links containing UUIDs
            # DPD200413054 Fix validation for broken links; Regex updated to account for '../' in href and removed matching the end quote. Some links end with element IDs in the URI
			while (m/ href=\"(([a-zA-Z#_\-=\w\.\/]+)\.html?)/gi) {
				$href_value_xml_ext=$1;
				# Ignore out link content containing www and http
				if ($href_value_xml_ext =~ m/www/) {
				}
				elsif ($href_value_xml_ext =~ m/http/) {
				}
				elsif ($href_value_xml_ext =~ m/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\.html?/) {
                    # DPD200413054 Fix validation for broken links; Get an accurate count of all href links encountered in htm in docbundle folder
						$href_value_xml_counter++;
					if (-e $href_value_xml_ext) {
						#$href_value_xml_counter++;
					}
					else {
						print LOGFILE "Referenced file $href_value_xml_ext in $File::Find::name cannot be found!\n";
						$href_value_xml_counter_missing++;
					}					
				}
				else {
                    # DPD200413054 Fix validation for broken links; Get an accurate count of all href links encountered in htm in docbundle folder
                    $href_value_xml_counter++;
						$href_value_xml_counter_missing++;
                    print LOGFILE "Referenced file $href_value_xml_ext in $File::Find::name is not in UUID form. Check that the source file exists and a UUID mapping exists in your mapping file.\n";
				}
			}			
			
			# Search for all src links
            # DPD200413054 Fix validation for broken links; Look for all src links, not just those that match a UUID	
			while (m/( src=\"([^"]+\.(g|j|p)\w\w\w?))/gi) {
				$href_value_src_img=$1;
				$href_value_img_ext=$2;
				# If image filename is in UUID form, check if file exists in this directory
				if ($href_value_src_img =~ m/ src=\"\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\.\w\w\w\w?/i) {
						$href_value_img_counter++;
					if (-e $href_value_img_ext) {
						#$href_value_img_counter++;
					}
					else {
						print LOGFILE "Referenced file $href_value_img_ext in $File::Find::name cannot be found!\n";
						$href_value_img_counter_missing++;
					}			
				}
				else {
                    $href_value_img_counter++;
						$href_value_img_counter_missing++;
                    print LOGFILE "Referenced file $href_value_img_ext in $File::Find::name is not in UUID form. Check that the source file exists and a UUID mapping exists in your  mapping file.\n";
				}
			}	
		}
		close A;
		return $href_value_xml_counter;
		return $href_value_img_counter;
		return $href_value_xml_counter_missing;
		return $href_value_img_counter_missing;
		
	}	
}
# ************************** End of function **************************

#
sub checkForDuplicateAliases() {
    my $parser = XML::LibXML->new(); # XML parser
    my $manifest = $parser->parse_file($manifestfile) or die "ERROR - Could not parse '$manifestfile': $!\n"; # Filehandle on parsed manifest file
    my %unique_aliases = ();  # Instantiate a hash for recording of unique aliases key=alias string, value=GUID
    
    foreach my $topic ($manifest->findnodes('/intel-swd-manifest/intel-swd-topic')) {
        my $alias           = $topic->find('@alias')->to_literal->value();
        my $id              = $topic->find('@id')->to_literal->value();
        
        if (!exists $unique_aliases{$alias}) {
            $unique_aliases{$alias} = $id;
        } else {
            print STDERR "ERROR! Found a duplicate alias '$alias', already defined for ID '$unique_aliases{$alias}'. Duplicate found on ID '$id'.\n";
            print LOGFILE "ERROR! Found a duplicate alias '$alias', already defined for ID '$unique_aliases{$alias}'. Duplicate found on ID '$id'.\n";
            $duplicateAliasCounter++;
        }
        # Check if alias + alias prefix is longer than 255 characters
        my $full_alias_length = $Alias_Prefix_Length + (length $alias);
        if ($full_alias_length > 255) {
            print STDERR "ERROR! Found an alias that is longer than '$DRUPAL_ALIAS_LIMIT' characters. See the alias defined in '$id'.\n";
            print LOGFILE "ERROR! Found an alias that is longer than '$DRUPAL_ALIAS_LIMIT' characters. See the alias defined in '$id'.\n";
        }
    }
}
