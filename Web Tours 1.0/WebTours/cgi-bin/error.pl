#!perl
# $Id: error.pl,v 1.3 2007-05-08 15:40:15 adish Exp $ [MISCCSID]

use CGI qw(:standard center);

require "systemPaths";

if (param('error') eq "usernameTaken") {
  	doUsernameTaken();
}
elsif (param('error') eq "badPassword") {
  	doBadPassword();
}
elsif (param('error') eq "missingEntry") {
	doMissingEntry();
}
else {
	doInvalidDataError();
}



sub doUsernameTaken {
  	printErrorHeader("Error - Username Taken");
  	print "<blockquote>\nThe username you've chosen is already in use.  Please choose \n",
        "another username for your account.  Usually, adding a personally \n",
        "significant number to the end of the username will be a unique \n",
        "username. ", p,"Thank you for your patience.\n</blockquote>",
        end_html();
}

sub doBadPassword {
	printErrorHeader("Error - Incorrect Password");
	print blockquote("\nThe username/password combination you've entered is invalid.  \n",
		"Please double check your entry.  If it still does not work, you might \n",
		"need to re-register with our site.", p, "Thank you for your patience.\n"),
		end_html();
}
		
sub doMissingEntry {
	printErrorHeader("Error - Missing Entry");
	print blockquote("\nBoth the username and password fields must be filled in.  ",
			"\nPlease double check your entry.", p, "Thank you for your patience.\n"),
		end_html();
}



sub printErrorHeader {
  $type = shift;
	print header, start_html(-title=>"Web Tours $type", -bgcolor=>"#E0E7F1");
	printCSS();
	print "<BR><BR><h1>&nbsp;&nbsp;<b>Error</b></h1><blockquote>";
	print center(h3("<font color=red>Web Tours $type</font>"));

}
sub printCSS {
	print "<style>blockquote {font-family: tahoma; font-size : 10pt}";
	print "H1 {font-family: tahoma; font-size : 22pt; color: #003366}";
	print "small {font-family: tahoma; font-size : 8pt}";
	print "H3 {font-family: tahoma; font-size : 10pt; color: black}";
	print "TD {font-family: tahoma; font-size : 8pt; color: black}";
	print "</style>";
}



sub doInvalidDataError {
	print header(-expires=>'10s'), 
				start_html(-title=>'Flight Selections', -bgcolor=>'white');

	print  "<img src=$imageBase/splash_error2.jpg width=390 height=90>","<center>",
			h2("Server Validation Error"),p, "</center>";
	print "<blockquote><font size=+1>Sorry, but something just isn't right with your data. \n",
			"Data gets corrupted in transit for a variety of reasons.  Sorry for the\n",
			"inconvenience, but you'll need to start this transaction over again.</font></blockquote>\n",p;
	print startform(-method=>'get', -action=>"welcome.pl?page=menus", -target=>"body");
	print "<center>";
	print image_button(-name=>"startOver",
						-border=>'0',
						-src=>"$imageBase/startover.gif");						
	print endform();
	print  "</center>", end_html();
}

