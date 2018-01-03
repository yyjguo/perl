#!c:/perl/bin/perl.exe
require "ctnlib/golden/cgi-lib.pl";
use Sybase::CTlib;
print "Content-type:text/html\n\n";
 

require "ctnlib/golden/common.pl";
#require "ctnlib/golden/datelib.pl";

&ReadParse();
$db = &connect_database();

print "ok";
exit;
#------------------------------------------------------------
#$IP="$ENV{'REMOTE_ADDR'}";
#------------------------------------------------------------
#$tag=$in{tag};
$Corp_ID=$in{Corp_ID};
if ($tag="skyecho_eteasy") {

	#print "OK";

}