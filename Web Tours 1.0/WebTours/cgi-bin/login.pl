#!perl
# $Id: login.pl,v 1.4 2008-04-17 11:32:24 aainbinder Exp $ [MISCCSID]

use CGI qw(:standard center);

require "systemPaths";
#
# Handles the login processes - 
# 	- validate a user logging in
#	- create new accounts (checking for valid usernames and passwords)
#

%options = cookie('MSO');

#
# Check the checksum values that are passed in...with those that we calculate
# ourself.
#

$checksum1 = join "", $options{'SID'} / 240, $options{'SID'} / 40000;
$checksum1 =~  tr/0123456789./AVcDtfzHiQp/;

$Lchecksum = join "", $options{'SID'} / 12345, $checksum1;

param('userValidation', $Lchecksum);


# register the userprofile.
if (param('register.x')) {
	doRegister();
}

# welcome them to the site.
elsif (param('intro')) {
	doIntro();
}

# get user profile
elsif (param('getInfo')) {
	doGetInfo();
}

# make sure that the userSession value is valid.
elsif ((!param('userSession')) || ($Lchecksum != param('userSession')) ) {
	doBadAccess();
}

# did we not get data from the JSFormSubmit on the nav.pl page?
elsif (($options{'JSFormSubmit1'}) && (param('JSFormSubmit') ne "on")) {
  	$url = url();
  	$url =~ s/reservations.pl/error.pl/;
  	print redirect("$url?error=invalidData");
  	exit(0);
}

# trying to login
elsif (param('login') || param('login.x')) {
	doLogin();
}

# trying to signup
elsif (param('signup.x') || param('signup')) {
		print header(-expires=>'5s');
		$username = param('username');


	# Validate that username is alphanumeric (remove all non-alphanumeric characters)
	# updated by Leonid Pekel on 16.04.2008
	$username =~ s/[^A-Za-z0-9]*//g;
	#


		$password = param('password');
		$c = "User sign-up...";
		$u1 = "nav.pl?in=signup&username=$username";
		$u2 = "login.pl?username=$username&password=$password&getInfo=true";
		printBodyFrames($c, $u1, $u2);
}

# illegal access
else {
	doLogin();
  	#doBadAccess();
}



################################################################################

#
# Create a new user account.  Make sure that the username isn't taken and that
# the password is valid.  If either problem exists - prompt them for data again.
#

sub doRegister {

	$username = param('username');
	$password = param('password');
	
# Validate that username is alphanumeric
# updated by Leonid Pekel on 16.04.2008
#
$original = $username;
$username =~ s/[^A-Za-z0-9]*//g;

if ($username eq $original)
{
#
#
	if (($password) && (param('passwordConfirm') eq $password)) {
		$result = createUser($username, $password);
		if ($result == 1) {
			doNewMember();
		}
		else {
			doGetInfo("Your username is taken.  Please choose another (usually adding a personally significant number to the end of your username will create a unique name).");		
		}
	}
	else {
		doGetInfo("Your password is invalid.  Please re-enter it and it's confirmation.");	
	}
}
else {
	doGetInfo("Your username is invalid.  Please re-enter it.");
}
}

#
# Creates the user.
# Save the user profile and password information in a file with the same name
# as the username.  The file goes into a directory as calculated by the hash
# value - so that the directories don't get too crowded.
#

sub createUser {
  my $name = shift;
  my $pass = shift;
  my $dir = rotatingHash($name);

  # move to the directory...
  chdir ("MTData");
  chdir ("users");
  chdir ("$dir");

  # if the file exists, return failure.
  if (-e $name) {
    return 0;
  }
  # creating file - the > creates and opens the file
  open(ACCOUNT, ">$name") or return 0;
  print ACCOUNT "$pass\n";
  print ACCOUNT param('firstName'), ";", param('lastName'), "\n",
		param('address1'), "\n", param('address2'), "\n;\n";
  close(ACCOUNT);
  
  chmod 0755, "$name";
  
  return 1;
}


#
# Check the user's given password with the registered password
#

sub doLogin {

	# Validate that username is alphanumeric (remove all non-alphanumeric characters)
	# updated by Leonid Pekel on 16.04.2008
	$username = param('username');
	$username =~ s/[^A-Za-z0-9]*//g;
	#

	if ((param('password')) &&
		(param('password') eq userPassword($username))) {
		$userCookie = makeUserCookie();
							
		print header(-expires=>'5s', -cookie=>$userCookie);
		$c = join "",
			"User password was correct - added a cookie with the user's default\n",
			"information.  Set the user up to make reservations...\n";
		$u1 = "nav.pl?page=menu&in=home";
		$u2 = "login.pl?intro=true";
		printBodyFrames($c, $u1, $u2);
		
	}
	else {

#		$username = param('username');
		$password = param('password');
		
		print header(-expires=>'5s');
		
		$c = "User password was incorrect.  Prompt the user to fix password or sign-up...";
		$u1 = "nav.pl?username=$username&password=$password";
		$u2 = "error.pl?error=badPassword";
		printBodyFrames($c, $u1, $u2);

	}

}

#
# print the frame layout - with a comment.
#

sub printBodyFrames {
	$comment = shift();
	$navURL = shift();
	$infoURL = shift();
	
	print <<EOF;
<!--
$comment
--->

<html>
<title>Web Tours</title>
<frameset cols="160,*" border=1 frameborder=1>
<frame src=\"$navURL\" name=\"navbar\" marginheight=\"2\" marginwidth=\"2\" noresize=\"noresize\" scrolling=\"auto\"/>
<frame src=\"$infoURL\" name=\"info\" marginheight=\"2\" marginwidth=\"2\" noresize=\"noresize\" scrolling=\"auto\"/>
</frameset>
EOF

	print end_html();

}
	
# 
# get the user's password from the user profile file.
#
#

sub userPassword {
  my $name = shift;
  my $dir = rotatingHash($name);

  chdir ("MTData");
  chdir ("users");
  chdir ($dir);

  if (-e $name) {
    open (ACCOUNT, "<$name") or die "Couldn't open";
    $pass = <ACCOUNT>;
    chomp($pass);

    #read in default information.

    ($one, $two) = split ";", <ACCOUNT>;
    param('firstName', $one);
    param('lastName', $two);
    $one = <ACCOUNT>;
    chomp ($one);
    param('address1', $one);
    $one = <ACCOUNT>;
    chomp ($one);
    param('address2', $one);
    ($one, $two) = split ";", <ACCOUNT>;
    param('creditCard', $one);
    param('expDate', $two);
    
    close(ACCOUNT);

  }
  else {
    $pass = "";
  }

  return $pass;
}


#
# Create a cookie with the user profile information stored in it.
#

sub makeUserCookie {
	@userFields = ('username', 'firstName', 'lastName', 'address1', 'address2',
				 	'creditCard', 'expDate');
					
	foreach $key (@userFields) {
		$userInfo{$key} = param($key);
	}
	
	$userInfo{'hash'} = rotatingHash(param('username'));

	return cookie(-name=>'MTUserInfo',
                    -value=>\%userInfo,
					-path=>"/");
}

#
# Gather user profile information
#

sub doGetInfo {
	$error = shift;
	$username = param('username');
	# Validate that username is alphanumeric (remove all non-alphanumeric characters)
	# updated by Leonid Pekel on 16.04.2008
	$username =~ s/[^A-Za-z0-9]*//g;
	#

	print header(-expires=>"5s"), start_html(-title=>"User Information",
		-bgcolor=>"#E0E7F1",
		-script=>{language=>'JavaScript', -src=>"$pageBase/profileValidate.js"});
	printCSS();
    	print "<BR/><center><H1><b><font color=\"#003366\">Customer Profile</font></b></H1></center>";

	
	if ($options{'MSO_JSVerify'}) {
		$JScript = 'return validateForm(this);';
	}
	print "<blockquote><tr><td><B>First time registering? Please complete the form below.</B><BR/>Please choose a username and password combination for your account.<BR/>",
		"We'd also like some additional contact information for yourself. We'll use it as default shipping and billing information when making all your travel arrangements.<P>",
		"<tr><td align=center>";

	if ($error) {
		print "<center><H3><font color=red>$error</font></H3></center>";
	}

	print	startform(-method=>"POST", -target=>"info",  -action=>"login.pl", -onSubmit=>$JScript);
	print
		table(
			TR( td( {-align=>"left"}, "<blockquote>Username : "),
				td( {-align=>"left"}, textfield(-name=>"username", -size=>20)) ),
			TR( td( {-align=>"left"}, "<blockquote>Password : "),
				td( {-align=>"left"}, password_field(-name=>"password", -size=>20)) ),							
			TR( td( {-align=>"left"}, "<blockquote>Confirm : "),
				td( {-align=>"left"}, password_field(-name=>"passwordConfirm", -size=>20)) ),
			TR( td( " ") ),
			TR( td( {-align=>"left"}, "<blockquote>First Name : "),
				td( {-align=>"left"}, textfield(-name=>"firstName", -size=>20)) ),
			TR( td( {-align=>"left"}, "<blockquote>Last Name : "),
				td( {-align=>"left"}, textfield(-name=>"lastName", -size=>20)) ),
			TR( td( {-align=>"left"}, "<blockquote>Street Address : "),
				td( {-align=>"left"}, textfield(-name=>"address1", -size=>30)) ),
			TR( td( {-align=>"left"}, "<blockquote>City/State/Zip : "),
				td( {-align=>"left"}, textfield(-name=>"address2", -size=>30)) ),
			TR( td( {-align=>"left"}, "&nbsp;"),
				td( {-align=>"right"}, "&nbsp;")),
			TR( td( {-colspan=>2, -align=>"center"}, image_button(-name=>'register', -border=>'0',
									-src=>"$imageBase/button_next.gif")) ),
			),
		endform(), "</table></blockquote>", end_html(), "\n";
		
}


#
# User is accessing this page incorrectly - link to the main home page so that their
# cookies and frames get reset properly.
#
#

sub doBadAccess {

	print header(-expires=>'5s'), start_html(-title=>'Illegal Access', -bgcolor=>"#E0E7F1");
	printCSS();
    	print "<blockquote>You've reached this page incorrectly (probably a bad user session value).  Please use ",
		a( {-href=>"$pageBase/index.htm", -target=>'_top'}, "this link.");

	print p,p,p,"The Variables are: ",br,dump() if (param('username') eq "vars");
	print end_html();

}

#
# Welcome the user...and new member.
#
#

sub doIntro {
	%userInfo = cookie('MTUserInfo');
	$username = $userInfo{'username'};
	# Validate that username is alphanumeric (remove all non-alphanumeric characters)
	# updated by Leonid Pekel on 16.04.2008
	$username =~ s/[^A-Za-z0-9]*//g;
	#

	print header(-expires=>"5s"), start_html(-title=>'Welcome to Web Tours', -bgcolor=>"#E0E7F1"),
		"",p;
	printCSS();
	print "<BR/><BR/><BR/><BR/><BR/><blockquote>Welcome, <b>$username</b>, to the Web Tours reservation pages.<BR/>",
		"Using the menu to the left, you can search for new flights to book, \n",
		"or review/edit the flights already booked.  Don't forget to sign off when\n",
		"you're done!\n";
	
	print p,p,p,"The Variables are: ",br,dump() if (param('username') eq "vars");
		
	print "</blockquote>", end_html();
}

sub doNewMember {

	$userCookie = makeUserCookie();
	$username = param('username');
	# Validate that username is alphanumeric (remove all non-alphanumeric characters)
	# updated by Leonid Pekel on 16.04.2008
	$username =~ s/[^A-Za-z0-9]*//g;
	#

	print header(-expires=>"5s", -cookie=>$userCookie), start_html(-title=>'Welcome to Web Tours', -bgcolor=>"#E0E7F1"),
		"\n<br/><br/><br/>\n\n\n",p;
	printCSS();
	print "<blockquote>Thank you, <b>$username</b>, for registering and welcome to the Web Tours family.\n",
		"We hope we can meet all your current and future travel needs.  If you have any questions, feel free \n",
		"to ask our support staff.   Click below when you're ready to plan your dream trip...",
		p, center("<a href=welcome.pl?page=menus target='body'><img src=$imageBase/button_next.gif border=0></a>");
		
	
	print p,p,p,"The Variables are: ",br,dump() if (param('username') eq "vars");
		
	print "</blockquote>", end_html();
}

#
# rotatingHash is a rotating hash.
# ala - http://ourworld.compuserve.com/homepages/bob_jenkins/examhash.htm
#
# takes a key and returns a value between 0 and 127, inclusive.
# editted for speed...
#

sub rotatingHash {
  my @chars = split //,shift;   # get item passed in, breaks into array of chars
  my $hash = scalar @chars;

  foreach $char (@chars) {
     $hash = ($hash << 5) ^ (ord $char);
  }

	 return ($hash & 127);
}

sub printCSS {
	print "<style>blockquote {font-family: tahoma; font-size : 10pt}";
	print "H1 {font-family: tahoma; font-size : 22pt; color: #993333}";
	print "small {font-family: tahoma; font-size : 8pt}";
	print "H3 {font-family: tahoma; font-size : 10pt; color: black}";
	print "TD {font-family: tahoma; font-size : 10pt; color: black}";
	print "</style>";
}