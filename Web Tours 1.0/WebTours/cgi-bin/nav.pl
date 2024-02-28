#!perl
# $Id: nav.pl,v 1.2 2007-05-08 15:40:18 adish Exp $ [MISCCSID]

#
# Handle the navigation bar...
# Basically, only two different modes - login and menus.
# But, it encodes the userSession that gets decoded by the login page. 
# It serves no real purpose, but is more of a mock up of something that
# a real site might do.
#
#
# 3 server options are handled in this page - 
#
# MSO_Comments
# MSO_JSFormSubmit1
# MSO_JSWPages
#
#

require "systemPaths";

use CGI qw(:standard center);

# get the server options
%options = cookie('MSO');


# create the checksum values.

$checksum1 = join "", $options{'SID'} / 240, $options{'SID'} / 40000;
$checksum1 =~  tr/0123456789./AVcDtfzHiQp/;
$checksum = join "", $options{'SID'} / 12345, $checksum1;


# this is the list of the labels/buttons that are displayed in the nav bar.
# by prefixing it with 'in_' will link to the grayed out button...

%labels = ( 'flights' => "flights.gif",
			'itinerary' => "itinerary.gif",
			'home' => "home.gif",
			'signoff' => "signoff.gif",
			'login' => "mer_login.gif",
			'signup' => "signoff.gif",
			'admin' => "admin.gif");


# adjust the images to represent the area that the user is currently...'in'.
if (param('in')) {
	$labels{param('in')} = "in_$labels{param('in')}" unless (param('in') eq 'signoff');
}

if (param('page') eq 'menu') {
  	showMenuPage();
}
else {
  	showDefaultPage();
}

###########################################################################


#
# Show the menu page - the image names have already be adjusted.
#

sub showMenuPage {
	print header(-expires=>'-1d'),
      	start_html(-title=>'Web Tours Navigation Bar',
                 -bgcolor=>'#E0E7F1'); 
	print <<EOF;

<style>
	blockquote {font-family: tahoma; font-size : 10pt}
	H1 {font-family: tahoma; font-size : 22pt; color: #993333}
	small {font-family: tahoma; font-size : 8pt}
	H3{font-family: tahoma; font-size : 10pt; color: black}
	A {FONT-WEIGHT: bold; FONT-SIZE: 10pt; COLOR: black; FONT-FAMILY: Tahoma; TEXT-DECORATION: none}
	A:hover{ FONT-WEIGHT: bold; FONT-SIZE: 10pt; COLOR: #993333; FONT-FAMILY: Tahoma;TEXT-DECORATION: underline}
	TD {font-family: tahoma; font-size : 10pt; color: black}
</style>

<BR><BR><center>

<br clear="both"/><center><A HREF="welcome.pl?page=search" TARGET="body"><IMG BORDER="0" SRC="$imageBase/$labels{'flights'}" 
ALT="Search Flights Button"/></A>
<br clear="both"/><A HREF="welcome.pl?page=itinerary" TARGET="body"><IMG BORDER="0" SRC="$imageBase/$labels{'itinerary'}" 
ALT="Itinerary Button"/></A>
<br clear="both"/><A HREF="welcome.pl?page=menus" TARGET="body"><IMG BORDER="0" SRC="$imageBase/$labels{'home'}" 
ALT="Home Button"/></A>
<br clear><A HREF="welcome.pl?signOff=1" TARGET="body"><IMG BORDER="0" SRC="$imageBase/$labels{'signoff'}" 
ALT="SignOff Button"/></A></center>
EOF

print end_html(), "\n";
}


#
# Display the login page...
#

sub showDefaultPage {

print header(-expires=>'-1d');

$username=param('username');
$password=param('password');


# for the comments, pretty much just print out the page, but with a bit of confusion
# added to the userSession value.

if ($options{'MSO_Comments'} eq 'on') {

	$confusion=int(rand(10000));
	print  <<EOF;	
<!-- Comments option is ON 

These are used to make the automated parsing difficult.
User must try and get the UserSession value.  There are several here, with similar boundaries.
But none are the right value.

<!DOCTYPE HTML>
<HTML><HEAD><TITLE>Web Tours Navigation Bar</TITLE>
<style>
	blockquote {font-family: tahoma; font-size : 10pt}
	H1 {font-family: tahoma; font-size : 22pt;color: #993333}
	small {font-family: tahoma; font-size : 8pt}
</style>
</HEAD><BODY BGCOLOR="#E0E7F1"><br clear="both"/>
<form method="post" action="login.pl" target="body">
<input type="hidden" name="userSession" value="$confusion$checksum"/>
<form method="post" action="error.pl" onSubmit="doJSformSubmit1(this)" target="body">
<input type="hidden" name="userSession" value="1$checksum"/>
<table border="0">
<tr><td><font face="sans-serif" size=2>&nbsp;</font></td></tr>
<tr><td><font face="sans-serif" size=2>&nbsp;Username</font></td></tr>
<tr><td><input type="text" name="username" value="" size="18" maxlength="30">
<tr><td><font face="sans-serif" size="2">&nbsp;Password</font></td></tr>
<tr><td><input type="password" name="password" value="" size="18" maxlength="30"/></td></tr>
<tr><td><input type="image" name="login" value="Login" alt="Login" border="1" src="$imageBase/mer_login.gif"/></td></tr>
</table></form></form>
</BODY></HTML>
-->
EOF

} # end of MSO_Comments

$actionURL = "/cgi-bin/login.pl";

if ($options{'MSO_JSFormSubmit1'} eq "on") {
	$actionURL = "error.pl\"  onSubmit=\"doJSFormSubmit1(this)";
	# can just add 3 characters to the front of checksum that javascript removes.
}
push @doc, "<style>";
push @doc, "blockquote {font-family: tahoma; font-size : 10pt}";
push @doc, "H1 {font-family: tahoma; font-size : 22pt; color: #993333}";
push @doc, "H3 {font-family: tahoma; font-size : 10pt; color: black}";
push @doc, "small {font-family: tahoma; font-size : 8pt}";
push @doc, "</style>";
push @doc, "<form method=\"post\" action=\"$actionURL\" target=\"body\">";
push @doc, "<input type=\"hidden\" name=\"userSession\" value=\"$checksum\"/>";
push @doc, "<table border=\"0\"><tr><td>&nbsp;</td>";
push @doc, "<td>&nbsp;</td></tr>";
push @doc, "<tr><td>&nbsp;</td>";
push @doc, "<td>&nbsp;</td></tr>";
push @doc, "<tr><td>&nbsp;</td>";
push @doc, "<td><small>&nbsp;Username</small></td></tr>";
push @doc, "<tr><td>&nbsp;</td>";
push @doc, "<td><input type=\"text\" name=\"username\" value=\"$username\" size=\"14\" maxlength=\"14\"/></td></tr>";
push @doc, "<tr><td>&nbsp;</td>";
push @doc, "<td><small>&nbsp;Password</small></td>";
push @doc, "<tr><td>&nbsp;</td>";
push @doc, "<td><input type=\"password\" name=\"password\" value=\"$password\" size=\"14\" maxlength=\"14\"/></td></tr>";
push @doc, "<tr><td>&nbsp;</td>";
push @doc, "<td>&nbsp;</td></tr>";
push @doc, "<tr><td>&nbsp;</td>";
push @doc, "<td><input type=\"image\" name=\"login\" value=\"Login\" alt=\"Login\" border=\"1\" ";
push @doc, "src=\"$imageBase/$labels{'login'}\"/></td></tr>";
push @doc, "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>";
push @doc, "</table><input type=\"hidden\" name=\"JSFormSubmit\" value=\"off\"/>";
push @doc, "</form>";

print start_html(-title=>'Web Tours Navigation Bar',
                 -bgcolor=>'#E0E7F1');

if ($options{'MSO_JSFormSubmit1'} eq "on") {
	print "<script language=\"Javascript\" src=\"$pageBase/JSFormSubmit.js\"> <!--- \n //Form submit is ON \n --> </script>\n";
}


if ($options{'MSO_JSWPages'} eq "on") {
	print "<script language=JavaScript> <!---\n";
	print "// This JavaScript will uses it's own write methods to display all the HTML code.\n",
		"// This means that the HTML code is generated on the client side - not the server side.\n",
		"// In some cases, if there was some calculation done to create the HTML, there could\n",
		"// problems discovering what the HTML actually is.  To examine those problems in more \n",
		"// detail, look into the other Server Options --> set/change URLs and calculating \n",
		"// data before it is put into a hidden field.\n\n\n\n";
	foreach $line (@doc) {
		print "document.writeln (\"$line\")\n";
	}
	
	print "//  --></script>\n";
}
else {
	foreach $line (@doc) {
		print "$line\n";
	}
}

print end_html(), "\n";

}

