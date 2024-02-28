#!perl
# $Id: welcome.pl,v 1.2 2007-05-08 15:40:19 adish Exp $ [MISCCSID]


#
# The welcome page.  It handles the bottom frame.  Generally, it splits
# the bottom frame into two more frames - the left (navigation) and right (info)
# frames.
#
# It also is used to reset the cookies on the client side when the user logs
# out. 
# 

use CGI qw(:standard);

require "systemPaths";

if (param('page') eq 'menus')  {
	showMenus();
}
elsif ((param('page') eq 'search') || (param('startOver'))) {
	showFlightSearch();
}
elsif (param('page') eq 'itinerary') {
	showItinerary();
}
else {
	showDefault();
}


##########################################################################

#
# show the menus - the search/itinerary/home/logout menu on the left,
# and the homepage on the right.  home button is shaded.
#

sub showMenus {

	print header();
	print <<EOF;
<!-- 
 User has returned to the home page.  Since user has already logged on,
 we can give them the menu in the navbar.
 --->

<html>
<title>Web Tours</title>
   <!-- Frame Set -->
   <frameset cols="160,*" border="1" frameborder="1">
      <!-- Navigation Frame -->
      <frame src="nav.pl?page=menu&in=home" name="navbar" 
            marginheight="2" marginwidth="2" noresize="noresize" scrolling="auto"/>
      <!-- Intro Frame -->
      <frame src="login.pl?intro=true" name="info" 
            marginheight="2" marginwidth="2" norseize="noresize" scrolling="auto"/>
   </frameset>
</html>
EOF

}

#
# start the flight search sequence...load the menu with the search button
# shaded...and start the flight intro page, allowing the users to search
# through the various flights available.
#

sub showFlightSearch {

	print header();
	print <<EOF;
<!-- 
 User has returned to the search page.  Since user has already logged on,
 we can give them the menu in the navbar.
 --->

<html>
<title>Web Tours</title>
   <!-- Frame Set -->
   <frameset cols="160,*" border="1" frameborder="1">
      <!-- Navigation Frame -->
      <frame src="nav.pl?page=menu&in=flights" name="navbar" 
            marginheight="2" marginwidth="2" norseize="noresize" scrolling="auto"/>
      <!-- Reservation Frame -->
      <frame src="reservations.pl?page=welcome" name="info" 
            marginheight="2" marginwidth="2" norseize="noresize" scrolling="auto"/>
   </frameset>
</html>
EOF

}

#
# load the itinerary pages into the info frame...and shade the itinerary
# button.
#

sub showItinerary {

	print header();
	print <<EOF;
<!-- 
 User wants the intineraries.  Since user has already logged on,
 we can give them the menu in the navbar.
 --->

<html>
<title>Web Tours</title>
   <!-- Frame Set -->
   <frameset cols="160,*" border="1" frameborder="1">
      <!-- Navigation Frame -->
      <frame src="nav.pl?page=menu&in=itinerary" name="navbar" 
            marginheight="2" marginwidth="2" noresize="noresize" scrolling="auto"/>
      <!-- Itinerary Frame -->
      <frame src="itinerary.pl" name="info" 
            marginheight="2" marginwidth="2" noresize="noresize" scrolling="auto"/>
   </frameset>
</html>
EOF

}


#
# This is the default page.  It gives the user two cookies. Once cookie
# is used as user information - it starts out with only a session value - which
# is used later on as a weak form of authentication.  The MSO cookie is used
# to maintain the server options as the user moves throughout the site.
# Load in the login navigation page, with the welcome to HP Software tours
# homepage.
#
# If the users directory doesn't exist in MTData, it will create it,
# and all its subdirectories.  Subdirectories are used to store usernames
# by hash values.
#

sub showDefault {

	# create a session ID - it's just the time for now..

	$cookie1 = fillCookie();

	# delete any old info and get a new server option cookie
	if (param('signOff')) {
		$cookie2 = cookie(-name=>'MTUserInfo', -value=>"",
							-path=>"/", -expires=>'-1d');
		print header(-cookie=>[$cookie1, $cookie2]);
	}
	# give them a cookie if they don't already have one.
	elsif (!cookie('MSO')) {
		print header(-cookie=>$cookie1);
	}
	else {
		print header();
	}
	
	
	# Framesets can't be in the body....

	print <<EOF;
<!-- 
 A Session ID has been created and loaded into a cookie called MSO.
 Also, the server options have been loaded into the cookie called
 MSO as well.  The server options can be set via the Admin page.
 --->

<html>
<title>Web Tours</title>
   <!-- Frame Set -->
   <frameset cols="160,*" border="1" frameborder="1">
      <!-- Navigation Frame -->
      <frame src="nav.pl?in=home" name="navbar" marginheight="2" marginwidth="2" 
            noresize="noresize" scrolling="auto"/>
      <!-- Home Frame -->
      <frame src="$pageBase/home.html" name="info" marginheight="2" marginwidth="2" 
            noresize="noresize" scrolling="auto"/>
   </frameset>
</html>
EOF

	print end_html();
	
	chdir ("MTData");	
	createDirectories() unless (-d "users");
}

#
# Utility functions to 
# 	build the necessary file structure
#	load the server options for a cookie
#	create the actual cookie.
#

sub createDirectories {

    mkdir ("users", 0777) unless (-d "users");
    chdir("users");
    for ($i = 0; $i < 128; $i++) {
		mkdir($i, 0777) unless (-d $i);
    }
}

sub loadServerOptions {
	%tempOptions = ( "SID" => time);
	
	$ip = remote_addr();
	$filename = $ip;
	$filename =~ s/\.//g;
	$filename .=".so";
	
	chdir("MTData");
  	open (ADMINFILE, "<$filename") or return %tempOptions;
  	$query = new CGI(ADMINFILE);
  	close ADMINFILE;  

  	@names = $query->param;
  	foreach $key (@names) {
    	$tempOptions{$key} = $query->param($key) unless ($key eq 'save');
  	}
  	
  	return %tempOptions;
}
	
sub fillCookie {  	
 	%options = loadServerOptions();

  	return cookie(-name=>'MSO',
                -value=>\%options,
				-path=>"/");
}


