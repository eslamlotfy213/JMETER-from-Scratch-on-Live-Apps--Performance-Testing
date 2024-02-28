#!perl
# $Id: reservations.pl,v 1.2 2007-05-08 15:40:18 adish Exp $ [MISCCSID]

use CGI qw(:standard);
require 'timelocal.pl';
require 'ctime.pl';
#use Time::Local;

#
# Reservation scripts - this is the heart of the application...
# Handles presenting all the flights and gathers the information
# for each flight.  
#
# Handles these server options - 
#	MSO_SErrors
#	MSO_SLoad
#	MSO_JSFormSubmit2
#	MSO_JSCalc
#	MSO_Verify
#	MSO_Redirect
#

require "systemPaths";
require "flightData";

%options = cookie('MSO');
%cookieData = cookie('MTUserInfo');
$userID = $cookieData{'username'};
$hash = $cookieData{'hash'};
$discountIndex = 0;



if (param('findFlights.x')) {

	# occasionally do a server error
	if ($options{'MSO_SErrors'}) {
		if (rand(100) <= $options{'MSO_ServerErrorsProb'}) {
			MakeErrorCall();
			exit(0);
		}
	}
	# select a flight the rest of the time.
  doFlightSelection();
}
elsif (param('reserveFlights.x')) {

	# occasionally do a load error
	if ($options{'MSO_SLoad'}) {
		if (rand(100) <= $options{'MSO_ServerLoadProb'}) {
			doServerError();
			exit(0);
		}
	}
	# make a reservation the rest of the time.
  doReservation();
}
elsif (param('buyFlights.x')) {
  if ($options{'MSO_JSFormSubmit2'}) {
  	if (param('JSFormSubmit') ne 'on') {
  		$url = url();
  		$url =~ s/reservations.pl/error.pl/;
  		print redirect("$url?error=invalidData");
  		exit(0);
  	}
  }
  
  # save the data as long as the hidden field was set properly
  saveData();
  showPurchaseSummary();
}

else {

  # present the user with the flight options.
  doIntro();
}

#
# display the possible flights
#
#

sub doFlightSelection {

	printSelectionHeader();
  	printFlightChoiceForm();
  	print "\n</blockquote>\n";
  	print p,p,p,"The Variables are: ",br,dump() if ($userID eq "vars");
  	print end_html;

}

#
# display the standard selection page
#
#

sub doIntro {
  #today's date
  ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
    localtime(time+(24*60*60));

  #tomorrow's date
  ($tsec, $tmin,$thour,$tmday,$tmon,$tyear,$twday,$tyday,$tisdst) =
    localtime(time+(24*60*60*2));

  # translate from 0 based indexing to 1 based...
  # and into 4 digit years - perl subtracts 1900 from the year.
  $mon++;
  $tmon++;
  
  $year += 1900;
  $tyear += 1900;
  
  # make sure the days and months are two digits
  
  $mon = "0$mon" if ($mon <= 9);
  $tmon = "0$tmon" if ($tmon <= 9);
  $mday = "0$mday" if ($mday <= 9);
  $tmday = "0$tmday" if ($tmday <= 9);

  printSelectionHeader();
  printSelectionForm();
  print "\n</blockquote>\n";
  print p,p,p,"\nThe Variables are: ",br,dump() if ($userID eq "vars");
  print end_html(), "\n";
}



#
# Displays the actual form displaying possible flights and user options.
#
# Handles - 
#	MSO_JSCalc
#	MSO_JSVerify
#


sub printSelectionForm {

	if ($options{'MSO_JSCalc'} eq 'on') {
		$jsCode = "setDIA(this);";
	}
	else {
		$jsCode = "";
	}
	
	if ($options{'MSO_JSVerify'} eq 'on') {
		$jsCode = $jsCode.' return validateForm(this);';
	}
	
	print startform(-method=>'POST', -action=>'reservations.pl',
					-name=>'DestForm',
					-onSubmit=>"$jsCode"),
		hidden(-name=>'advanceDiscount', -value=>'0');

        $appDept = "\n" .
                   "<!-- Departure Date Applet -->\n" .
                   "<APPLET CODEBASE=\"/WebTours/classes/\" CODE=\"FormDateUpdate.class\" MAYSCRIPT Width=26 Height=28 BORDER=0>\n" .
                   "   <PARAM NAME=CalenderTitle  VALUE=\"Select Departure Date\">\n" .
                   "   <PARAM NAME=HtmlFormIndex  VALUE=0>\n" .
                   "   <PARAM NAME=HtmlEditIndex  VALUE=2>\n" .
                   "   <PARAM NAME=AutoClose      VALUE=1>\n" .
                   "   <PARAM NAME=Label          VALUE=\"...\">\n" .
                   "</APPLET>\n";

        $appRet = "\n" .
                   "<!-- Return Date Applet -->\n" .
                   "<APPLET CODEBASE=\"/WebTours/classes/\" CODE=\"FormDateUpdate.class\" MAYSCRIPT Width=26 Height=28 BORDER=0>\n" .
                   "   <PARAM NAME=CalenderTitle  VALUE=\"Select Return Date\">\n" .
                   "   <PARAM NAME=HtmlFormIndex  VALUE=0>\n" .
                   "   <PARAM NAME=HtmlEditIndex  VALUE=4>\n" .
                   "   <PARAM NAME=AutoClose      VALUE=1>\n" .
                   "   <PARAM NAME=Label          VALUE=\"...\">\n" .
                   "</APPLET>\n";

	print table( {-cellspacing=>'5', -border=>'0'},
			TR( td( {-align=>'left'}, "Departure City :"), 
				td( popup_menu(-name=>'depart', -values=>\@cities, -default=>'Denver') ),
				td( {-align=>'left'}, "Departure Date :"),
				td( textfield(-name=>'departDate', -default=>"$mon\/$mday\/$year",
				 			-size=>10, -maxlength=>10) , $appDept )  ),
			TR( td( {-align=>'left'}, "Arrival City :"), 
				td( popup_menu(-name=>'arrive', -values=>\@cities, -default=>'Denver') ),
				td( {-align=>'left'}, "Return Date :"),
				td( textfield(-name=>'returnDate', -default=>"$tmon\/$tmday\/$tyear",
				 			-size=>10, -maxlength=>10) , $appRet )  ),
			TR( td( {-align=>'left'}, "No. of Passengers : "),
				td( textfield(-name=>'numPassengers', -default=>"1", -size=>3, -maxlength=>8) ),
				td( {-colspan=>'2'},
				 		checkbox(-name=>'roundtrip', -label=>'Roundtrip ticket') ) ),
			TR( td( "Seating Preference" ), td, 
				td( "Type of Seat") ),
			TR( td( radio_group(-name=>'seatPref', -values=>['Aisle', 'Window', 'None'],
						-default=>'None', -linebreak=>'true') ), td(),
				td( radio_group(-name=>'seatType', -values=>['First', 'Business', 'Coach'],
						-default=>'Coach', -linebreak=>'true') ) ),
			TR( td( {-height=>'10'})),
			TR( td( {-colspan=>'4', -align=>'center'},
						image_button(-name=>"findFlights", 
									-border=>'0',
									-src=>"$imageBase/button_next.gif") ) )		
			);
		
	print endform();
		
}

#
# The form for presenting a flight choice
#
# 

sub printFlightChoiceForm {

    	
    if (param('advanceDiscount') == calculateAD()) {
   		$discountIndex = int(param('advanceDiscount') / 7);
		$discountIndex = 3 if ($discountIndex > 3);
	}    		


	print startform('POST', 'reservations.pl');
	print "\n<center>";
		
	printFlightChoices(param('depart'), param('arrive'), 
                   param('departDate'), "outboundFlight");
	if (param('roundtrip')) {
  		print "<P>";
  		
  		printFlightChoices(param('arrive'), param('depart'),
                   param('returnDate'), "returnFlight");
    }

	print hidden(-name=>'numPassengers'),
			hidden(-name=>'advanceDiscount'),
			hidden(-name=>'seatType'),
			hidden(-name=>'seatPref'),
  			"\n<P>","<center><table width=80% cellspacing=1><tr><td align=center>\n";
  	print image_button(-name=>"reserveFlights",
						-border=>'0',
						-src=>"$imageBase/button_next.gif"),						
			"\n<td>&nbsp;<td align=center>",	
			"</table></center>",
			endform(),
			"</center>";

}
  
#
# The radio boxes for the flight choices for the cities selected by the user
#

sub printFlightChoices {
  	my $city1 = shift;
  	my $city2 = shift;
  	my $flightDate = shift;
  	my $flightType = shift;
  	my $city1Num = $cityNum{$city1};
  	my $city2Num = $cityNum{$city2};

    print "\n<!-- From $city1 ($city1Num) To $city2 ($city2Num) -->\n";

  	print  "<table cellspacing=\"2\" border=\"0\" width=\"50%\">\n",
  		"<blockquote>Flight departing from <B>$city1</B> to <B>$city2</B> on <B>$flightDate</B>",
  		"<BR/><BR/>",
      		"<tr bgcolor=\"#5E7884\"><td align=\"center\"><font color=\"white\"><B>Flight</B></font>
      		<td align=\"center\"><font color=\"white\"><B>Departure time</B>
      		<td align=\"center\"><font color=\"white\"><B>Cost</B>\n";

  	# 4 flights a day

  	for ($i = 0; $i < 4; $i++) {

    	# flight num is the time of day, dept city, arr city

		$numPass = param('numPassengers');
    	#$flightNum = join "", $city1Num, $city2Num, $i;
		$flightNum  = "" . $city1Num . $city2Num . $i;
    	$flightTime = $flightTimes[$i];
    	$flightPrice = int($prices[$city1Num][$city2Num] *
                 		$timeDiscounts[$i] * 
                 		$classIncreases[$classes{param('seatType')}] *
                 		$advanceDiscounts[$discountIndex]);
		if (($i % 2) == 0) {	
			$color = "#EFF2F7";
		}
		else {
			$color = "#EFF2F7";
		}
    	print "<tr bgcolor=\"$color\"><td align=\"center\"><input type=\"radio\" name=\"$flightType\" ",
        	"value=\"$flightNum;$flightPrice;$flightDate\"";
 
	   	print " checked=\"checked\" " if ($i == 0);

    	print ">Blue Sky Air $flightNum<td align=\"center\">$flightTime<td align=\"center\">\$ $flightPrice</TD></TR>";
  	}

  	print "</table>\n\n";
}

#
# Get the payment information in order to reserve the flight.
#

sub doReservation {
	%cookieData = cookie("MTUserInfo");
	@userFields = ('firstName', 'lastName', 'address1', 'address2',
				 	'creditCard', 'expDate', 'saveCC');
					
	foreach $key (@userFields) {
		param($key, $cookieData{$key});
	}
	
	print header(-expires=>'-1d'), start_html(-title=>"Flight Reservation",
								-bgcolor=>"#E0E7F1");

	($outFlight, $outCost, $outDate) = split(";", param('outboundFlight'));
	($retFlight, $retCost, $retDate) = split(";", param('returnFlight'));

	$totalCost = ($outCost + $retCost) * param('numPassengers');

	printCSS();
	print "<BR/><BR/><h1><font color=\"#003366\">&nbsp;&nbsp;<b>Payment Details</font></b></h1><blockquote>";

	if ($options{'MSO_JSVerify'} eq 'on') {
		print "<SCRIPT src=$pageBase/purchaseValidate.js>",
		'document.write("Included JS file not found")</SCRIPT>';
		$jscript = "validateForm(this)";
	}
	else {
		$jscript = "true";
	}
	
	if ($options{'MSO_JSFormSubmit2'}) {
		print "<SCRIPT src=\"$pageBase/JSFormSubmit.js\">",
		'document.write("Included JS file not found")</SCRIPT>',
			<<EOF;

<!--  JSFormSubmit Server Option is ON

The action tag is empty on purpose.  The javascript called when the form is submitted.
The javascript will tweak some values, set the action location (where the data should
be submitted to) and then submit the data.

Finally, the JavaScript handler returns FALSE.  This inhibits the normal form submission
via the form's defintion in HTML.

Since these are images instead of submit buttons and JavaScript doesn't have an onClick
handler for image buttons, the form's onSubmit handler must be used.  However, if a 
form used normal submit buttons and an onClick handler, the javscript code and behavior
would be very similar.

--->

EOF

		print startform(-name=>"JSFormSubmitForm2", 
						-action=>'error.pl?error=invalidData', 
						-method=>"POST",
						-onSubmit=>"if ($jscript) {doJSFormSubmit2(this) }");
	}
	else {
		print startform(-method=>'POST', 
						-action=>'reservations.pl',
						-onSubmit=>"return $jscript ;");
	}
	
	printUserInputFields();

	print hidden(-name=>'numPassengers'),
			hidden(-name=>'seatType'),
			hidden(-name=>'seatPref'),
			hidden(-name=>'outboundFlight'),
			hidden(-name=>'advanceDiscount'),
    	  	hidden(-name=>'returnFlight'),
    	  	hidden(-name=>'JSFormSubmit', -value=>"off");
   	print 	"<center><table width=80% cellspacing=1><tr><td align=center>\n",
    	  	image_button(-name=>"buyFlights",
						-border=>'0',
						-src=>"$imageBase/button_next.gif"),
			endform();
	print 	"\n<td>&nbsp;<td align=center>",
			startform(-method=>'post', 
					-action=>'reservations.pl',
					-onSubmit=>"void(0);");
	print endform(),
			"</table></center></blockquote>";

	print p,p,p,"The Variables are: ",br,dump() if ($userID eq "vars");
	print end_html;
	
}


#
# Get the purchase information for the ticket. 
# validation is going on here too...
#

sub printUserInputFields {

  	param('saveCC', 'on') if (param('creditCard'));
  	param('oldCCOption', 'on') if (param('creditCard'));

  	print "<table><tr>",
        "<td align=\"right\">First Name : <td>", 
        textfield(-name=>'firstName',
                 -size=>15),
        "<tr><td align=\"right\">Last Name : <td>",
        textfield(-name=>'lastName',
                  -size=>15),
        "<tr><td align=\"right\">Street Address : <td colspan=\"3\">",
        textfield(-name=>'address1',
                  -size=>30),
        "<tr><td align=\"right\">City/State/Zip : <td colspan=\"3\">",
        textfield(-name=>'address2',
                  -size=>30),
        "<tr><td align=\"right\">Passenger Names : <td colspan=\"3\">",
		textfield(-name=>'pass1', -size=>'30', 
					-default=>(join " ", param('firstName'), param('lastName')));
		
	$i = 1;
	while ($i < param('numPassengers')) {
		$i++;
		print "<tr><td><td colspan=\"3\">",
			textfield(-name=>"pass$i", -size=>'30');
	}
       
	print	"<tr><td height=\"10\"><tr><td height=\"10\" align=\"center\" colspan=\"4\">Total for ", 
		param('numPassengers'),
		" ticket(s) is = \$ $totalCost",
        "<tr><td align=\"right\">Credit Card : <td>",
        textfield(-name=>'creditCard',
                  -size=>20, -maxlength=>20),
        "<td align=\"right\">Exp Date : <td>",
        textfield(-name=>'expDate',
                  -size=>5, -maxlength=>5),
        "<tr><TD><td colspan=\"3\" align=\"left\">",
        checkbox(-name=>'saveCC',
                 -label=>'Save this Credit Card Information'),
        hidden(-name=>"oldCCOption"),
        "</table>";
}


#
# saves to disk in this format
#
# firstName;lastName
# address;city;state;zip
# creditCard;expdate;saveCardNumber
# ;passenger1;passenger2;etc....
# outboundFlight;outboundPrice;outboundDate
# returnFlight;returnPrice;returnDate
#
# One way flights will be represented with return flight 0;0;0
#

sub saveData {
	chdir("MTData");
  	chdir("users");
  	chdir($hash);

	param('hash', $hash);
  	if (-e $userID) {
    	open (ACCOUNT, ">>$userID");
    	print ACCOUNT param('firstName'), ";", param('lastName'), "\n",
                   param('address1'), "\n",
                   param('address2'), "\n";
        
       	print ACCOUNT param('creditCard'), ";",
                  param('expDate'), "\n";
    	
    	print ACCOUNT param('numPassengers'), ";", param('seatType'), ";", param('seatPref'), "\n";
    	
    	for ($i = 0; $i < param('numPassengers'); $i++) {
    		print ACCOUNT param("pass$i"), ";";
    	}
    	
    	print ACCOUNT param("pass$i"), "\n";
    		
    	print ACCOUNT param('outboundFlight'), "\n";

    	if (param('returnFlight')) {
      		print ACCOUNT param('returnFlight'), "\n";
    	}
    	else { # no return flight
      		print ACCOUNT "0;0;0\n";
    	}
    	
    	close(ACCOUNT);
    	
    	param('savedData', "false");
    	if (  (  (!(param('saveCC'))) && (param('oldCCOption'))) ||
    		  (  (!(param('oldCCOption'))) && (param('saveCC'))) ||
    			(param('saveCC') != param('oldCCOption'))) {
	    	# save the card number as the default card number.
   			updateCardNumber();
   			param('savedData', "true");
    	}
  	}
  	else {
    	return 0;
  	}

  	return 1;
}


#
# Shows a single purchase summary
#
#

sub showPurchaseSummary {
  	($outboundFlight, $outboundPrice, $outboundDate) = split ";",param('outboundFlight');;
  	($returnFlight, $returnPrice, $returnDate) = split ";", param('returnFlight');;
  	$totalPrice = ($outboundPrice + $returnPrice) * param('numPassengers');


	if (($options{'MSO_Redirect'}) || (param('dotest'))) {
		cleanUp(.001);  # 1.44 minutes.
		$filename = join ".", time, "html";
		open (OUTPUT, ">$filename");
		
	}
	else {
		open (OUTPUT, ">-");
	}
	
	
	if (param('saveCC')) {
		%cookieData = cookie('MTUserInfo');
		$cookieData{'creditCard'} = param('creditCard');
		$cookieData{'expDate'} = param('expDate');
	}
	else {
		%cookieData = cookie('MTUserInfo');
		delete $cookieData{'creditCard'};
		delete $cookieData{'expDate'};
	}


	$newCookie = cookie(-name=>'MTUserInfo',
						-value=>\%cookieData,
						-path=>"/");
	
	if (!$options{'MSO_Redirect'}) {
	 	print OUTPUT header(-expires=>'-1d', -cookie=>$newCookie);
 	}
 	
 	
 	print OUTPUT start_html(-title=>"Reservation Made!", -bgcolor=>"#E0E7F1");	

	printCSS();
	print OUTPUT "<BR/><BR/><h1><font color=\"#003366\">&nbsp;&nbsp;<b>Invoice</font></b></h1><blockquote>";

  	print OUTPUT "\n<CENTER>\n",
	             "<small><B>Thank you for booking through Web Tours.</B></small>\n";
	print OUTPUT "<BR/>\n<BR/>\n";

    $date = &ctime(time);
    print OUTPUT "<!-- Customer Name header -->\n",
	             "<Table width=\"85%\" border=\"0\" cellspacing=\"0\" >\n",
				 "  <TR bgcolor=\"#5E7884\">\n",
				 "     <TD colspan=\"2\" align=\"center\">\n",
				 "        <font color=\"white\"><b>", 
				 param('firstName') , param('lastName') ,
				 "'s Flight Invoice</b></font>\n",
				 "     </TD>\n",
				 "     <TD width=\"160\" align=\"right\">\n",
				 "         <font color=\"white\"><small>$date</small>\n",
				 "     </TD>\n",
				 "  </TR>\n",
				 "</Table>\n\n";

	print OUTPUT "<Table width=\"85%\" border=\"0\" cellspacing=\"1\" >\n",
				 "<!-- Flight Item header -->\n",
				 "  <TR bgcolor=\"#EFF2F7\">\n",
				 "     <TD colspan=\"2\" align=\"left\">\n",
				 "         Flights Reservation Requests:\n",
				 "    </TD>\n",
				 "    <TD align=\"center\">Cost\n",
				 "    </TD>\n",
				 "  </TR>\n\n";
    print OUTPUT "<!-- Flight reserved -->\n",
	             "<TR bgcolor=\"#EFF2F7\">\n",
				 "    <TD valign=\"top\">1.</TD>\n",
				 "    <TD align=\"left\">\n";
	if ( int(param('numPassengers')) == 1) {
	    print OUTPUT "       A ",
		             param('seatType'), " Class ticket\n";
	} else {
	    print OUTPUT "       <b><u>",
		             param('numPassengers'), " ",
		             param('seatType'), " Class tickets";
	}
        print OUTPUT " from ", $cities[int ($outboundFlight / 100)] ,
                     " to " , $cities[int ($outboundFlight / 10) % 10] ,
                     ".</u></b>\n";
	 
	print OUTPUT "<br/>\n<center>\n       <i>\n",
	             "          $outboundDate : ";
	printFlightDesc($outboundFlight, OUTPUT);
	print OUTPUT "\n";

	if ($returnFlight != 0) {
	    print OUTPUT "          $returnDate : ";  
	    printFlightDesc($returnFlight, OUTPUT);
	    print OUTPUT "<br/>\n";
	}

	
	print OUTPUT "       <br/>\n",
	             "    </TD>\n",
	             "    <TD valign=\"top\">\n",
	             "         \$$totalPrice\n",
	             "    </TD>\n",
	             "  </TR>\n";

	print OUTPUT "<!-- Total Cost -->\n",
	             "  <TR bgcolor=\"#EFF2F7\">\n",
	             "    <TD>*\n",
	             "    </TD>\n",
	             "    <TD > Total Cost\n",
	             "    </TD>\n",
	             "    <TD>\n",
	             "       <b> \$$totalPrice </b>\n",
	             "    </TD>\n",
	             "  </TR>\n",
	             "\n",
	             "  <TR bgcolor=\"#EFF2F7\">\n",
	             "    <TD>-\n",
	             "    </TD>\n",
	             "    <TD >\n",
	             "       Total Charged to Credit Card # ", param('creditCard'), "\n",
	             "    </TD>\n",
	             "    <TD>\n",
	             "       <b> \$$totalPrice </b>\n",
	             "    </TD>\n",
	             "  </TR>\n",
	             "\n",
	             "  <TR bgcolor=\"#EFF2F7\">\n",
	             "    <TD>*\n",
	             "    </TD>\n",
	             "    <TD >\n",
	             "        Credit Account Balance\n",
	             "    </TD>\n",
	             "    <TD>\n",
	             "       <b> \$0.00 </b>\n",
	             "    </TD>\n",
	             "  </TR>",
	             "</Table>\n",
	             "<BR/>\n";

	print OUTPUT "<Table width=\"85%\" border=\"0\">\n",
	             "  <tr>\n",
	             "    <td align=right>\n";

	print OUTPUT startform(-method=>'post', -action=>"$resScript"),
  		 		image_button(-name=>"Book Another",
						-border=>'0',
						-src=>"$imageBase/bookanother.gif"),
  				endform();
	print OUTPUT "    </td>\n",
	             "  </tr>\n",
	             "</Table>\n\n",
	             "</Center>\n";

  	print OUTPUT p,p,p,"\nThe Variables are: ",br,dump() if ($userID eq "vars");
  	print OUTPUT end_html();
  	
	if (($options{'MSO_Redirect'}) || (param('dotest'))) {
		close(OUTPUT);
		$url = url();
		$filename = "MTData/users/$hash/$filename";
		$url =~ s/reservations.pl/$filename/;
		print redirect(-method=>'GET', -location=>$url, -cookie=>$newCookie);
	}
}


# 
# Saves the new credit card number for default use (can be empty to erase
# the card number from the default use).
#

sub updateCardNumber {
	
	open (ACCOUNT, "<$userID");
	@lines = <ACCOUNT>;
	close (ACCOUNT);
	
	open (ACCOUNT, ">$userID");
	$i = 0;
	foreach $line (@lines) {
		# credit card info goes on the 5th line
		if ($i == 4) {
			if (param('saveCC')) {
				print ACCOUNT param('creditCard'), ";", param('expDate'), "\n";
			}
			else {
				print ACCOUNT ";\n";
			}
		}
		else {
			print ACCOUNT $line;
		}
		$i++;
	}
	close (ACCOUNT);
}

#
# Calculate the days in advance of the purchase.  Used to verify the
# discount provided by the javascript data.
#


sub calculateAD {
    ($mon, $mday, $year) = split "/", param('departDate');
    $mon--;
    $year -= 1900;
    $ticketDate = timelocal(59, 59, 23, $mday, $mon, $year);
    $diff = $ticketDate - time;

    return int ($diff / (60 * 60 * 24)) ;
}

#
# Present the user with a fake server load error. 
# A form is presented, maintaining all the data in hidden fields, so that the
# user can re-try the submission. Since it's a probabilistic error, there can
# be a chance of success.
#

sub doServerError {
	print header(-expires=>'-1d', -status=>"503 System Cannot Complete Request"), 
				start_html(-title=>'Flight Selections', -bgcolor=>'#E0E7F1');
	printCSS();
	print "<center>", h1("Server Database Error"),p,
			"<blockquote>Sorry, but our system is currently overloaded and cannot process your \n",
			"request at the moment.  Please wait a few moments and resubmit your request.\n",
			"If that does not work, please start your purchase over.  Again, sorry for the \n",
			"inconvenience.\n",p;
	print 	startform('POST', 'reservations.pl'),
			hidden(-name=>'numPassengers'),
			hidden(-name=>'advanceDiscount'),
			hidden(-name=>'outboundFlight'),
			hidden(-name=>'reutrnFlight'),
			hidden(-name=>'seatType'),
			hidden(-name=>'seatPref'),  	
			"\n<P>";
	print 	"<center><table width=80% cellspacing=10><tr><td align=center>\n",			
			"\n<td>&nbsp;<td align=center>",	
			image_button(-name=>"reserveFlights",
						-border=>'0',
						-src=>"$imageBase/resubmit.gif");
	print 	"</table></center>",
			endform(),
			"</center>", end_html();

}


#
# Displays the standard header for the selection pages.
#
#

sub printSelectionHeader {
	print header(-expires=>'-1d'), start_html(-title=>'Flight Selections',
                         -bgcolor=>'#E0E7F1');
	printCSS();
	print "<BR/><BR/><h1><font color=\"#003366\">&nbsp;&nbsp;<b>Find Flight</font></b></h1><blockquote>\n";



	if ($options{'MSO_JSCalc'} eq 'on') {
		print "\n\n\n<!--  JSCalculate Server Option -->\n",
			"<SCRIPT src=\"$pageBase/JSCalculate.js\">",
			'document.write("Included JS file not found")</SCRIPT>',
			<<EOF;

<!---
JSCalculate Server Option comment.

This JavaScript will calculate the days in advance",
for the ticket purchase.  This value is passed along in the 
hidden form variable - 'advanceDiscount'.  The only way the 
advance discount variable will change is via this JavaScript,
the server side CGI scripts do not alter it.  So, in order to
get the discount, the javascript (or something equivalent)
must calculate the days in advance.

Cheating will not be allowed - even though the server does not
adjust the advanceDiscount field, it does double check it if
it is not zero.

Currently, the airline has discounts for 7, 14, and 21 day in
advance ticket purchases.
-->
EOF

	} # end of JSCalculate option
		
	if ($options{'MSO_JSVerify'} eq 'on') {
		print "\n\n<!--- JSVerification Server Option -->\n",
			"<script src=\"$pageBase/chooseFlightValidate.js\">",
			'document.write("Included JS file not found")</SCRIPT>';
	}


}


#
# When there are redirects to html files, the html files must be created on the
# server disk.  This routine will clean up the old files (old is about 1.5 minutes).
# 

sub cleanUp {
	$age = shift;
	
	opendir THISDIR, ".";
	@allfiles = grep -T, readdir THISDIR;
	closedir THISDIR;

	foreach $file (@allfiles) {
    	if (-M $file > $age) {
    	    push @oldies, $file;
    	}
	}
	# only delete those that are .html files.
	@oldies = grep /\.html$/, @oldies; 
	unlink @oldies;
}

sub printCSS {
	print "<style>blockquote {font-family: tahoma; font-size : 10pt}";
	print "H1 {font-family: tahoma; font-size : 22pt; color: #993333}";
	print "small {font-family: tahoma; font-size : 8pt}";
	print "H3 {font-family: tahoma; font-size : 10pt; color: black}";
	print "TD {font-family: tahoma; font-size : 10pt; color: black}";
	print "</style>";
}