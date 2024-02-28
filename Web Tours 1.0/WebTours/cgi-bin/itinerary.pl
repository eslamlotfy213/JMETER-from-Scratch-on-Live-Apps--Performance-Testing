#!perl
# $Id: itinerary.pl,v 1.3 2007-05-08 15:40:17 adish Exp $ [MISCCSID]

#
# Displays the itinerary.
# or - removes flights from the itinerary...and then displays the itinerary.
#
# Handles these server options :
#	MSO_Redirects
#


use CGI qw(:standard) ;

require "systemPaths";
require "flightData";

#
# init some data 
#

%cookieData = cookie('MTUserInfo');
$userID = $cookieData{'username'};
$hash = $cookieData{'hash'};
%options = cookie('MSO');

$DEFAULTINFOLINES = 5;
$LINESPERFLIGHT = 8;

# store the dump data now - later on we will be resetting the value of
# param('flightID') and don't want to effect the dump().
#$dumpData = dump();
	

if (param('removeAllFlights.x')) {
	if (!removeFlights()) {
		showError();
		exit(0);
	}
}
elsif (param('removeFlights.x')) {
	if (!removeFlights()) {
		showError();
		exit(0);
	}
}

showSummary();


##############################################################################

#
# Display all the flights stored in the user's account.  Nothing really tricky.
#

sub showSummary {
   	printItineraryHeader();

	print "<BR/><BR/><h1><font color=\"#003366\">&nbsp;&nbsp;<b>Itinerary</font></b></h1><blockquote>";
  	chdir("MTData");
  	chdir("users");
  	chdir($hash);


  	open (ACCOUNT, "<$userID");
  	for ($i = 0; $i < $DEFAULTINFOLINES; $i++) {
  		$defaultInfo = <ACCOUNT>;
  	}

  	$ticketNum = 1;
  	
  	$itinURL = "itinerary.pl";
  	
  	# if the redirect option is on - post to the localredirect.pl file...not
  	# this file.
  	
  	if ($options{'MSO_Redirects'}) {
  		$itinURL = "localredirect.pl";
  		print <<EOF;
  		
  		
<!--   Redirects option is ON.

This form no longer submits to itinerary.pl. 

Instead, it is submitting to localredirect.pl, with some additional hidden values.
This redirect script will parse the additional hidden values and then return
the location of the page that the user should goto.

--->


EOF
  	}
  	
    # START OF FORM 
  	print startform(-method=>"POST", -action=>$itinURL);
  	
  	# while there are flights left, print them out.
  	while (!(eof ACCOUNT)) {

            # Read in all variables -------------------------------------
            # Read firstName and lastName
	  		($firstName, $lastName) = split ";", <ACCOUNT>;
            # Read address1
  			$address1 = <ACCOUNT>;
 	 		chomp ($address1);
            # Read address2
  			$address2 = <ACCOUNT>;
  			chomp ($address2);
            # Read last 4-digits of creditCard and expDate
  			($creditCard, $expDate) = split ";", <ACCOUNT>;
  			$creditCard = substr $creditCard, -4;  # last 4 digits of card
            # Read number of Passengers, seatType, and seat preference
  			($numPassengers, $seatType, $seatPref) = split ";", <ACCOUNT>;
            # Read PassList (PassengerList)
  			@passList = split ";", <ACCOUNT>;
            # Read outboundFlight, outboundPrice, and outboundDate
  			($outboundFlight, $outboundPrice, $outboundDate) = split ";", <ACCOUNT>;
            # Read returnFlight, returnPrice, returnDate
  			($returnFlight, $returnPrice, $returnDate) = split ";", <ACCOUNT>;
            # Calculate total price
  			$totalPrice = ($outboundPrice + $returnPrice) * $numPassengers;

            # ... HEADER .........................................................
			if ($ticketNum == 1) {

               # Print start of Table
               print "<center>\n" .
                            "<TABLE BORDER=\"0\" WIDTH=\"85%\" CELLSPACING=\"0\">\n";
		print "<TR bgcolor=\"#5E7884\">\n";
		print "  <TD colspan=\"4\" align=\"center\"><font color=\"white\"><B>$firstName $lastName 's Flight Transaction Summary</B></color></TD></TR>\n";
            }

            # ... Background color ................................................
            if ( $ticketNum % 2 == 1 ) {
                $bgcolor = "#EFF2F7";
            } else {
                $bgcolor = "#EFF2F7";        
            }

            # ... Flight Information ..............................................
            print "\n";
            print "<!-- Flight #" , $ticknum , "1 -->\n";
            print "<TR bgcolor=\"$bgcolor\">\n";
            print "  <TD width=\"5%\" rowspan=\"2\" align=\"left\" valign=\"top\">\n";

            # Check Box
            print "<b>\n" ,
                  checkbox(-name=>"$ticketNum", -value=>'on', -label=>""),
                  "</font></b>\n";

  			# add this ticket number to the flightID variable
  			$id1 = "$creditCard$outboundFlight$outboundPrice";
			$id2 = "$ticketNum$returnFlight$totalPrice";
  			$id1 = int ($id1 / 27);
			$id2 = int ($id2 / 13);
			$id  = "$id1-$id2-" . substr($firstName,0,1) . substr($lastName,0,1);

	  		param('flightID', $id);
  			print hidden(-name=>"flightID");

         
	    # Print ticket Number
            print "\n  </TD>\n";
            print "  <TD width=\"45%\" valign=\"top\">\n";
            
            # Tickets and class
            if ($numPassengers == 1) {
                 print "      <b>&nbsp;&nbsp;A " ,
                      $seatType , " class ticket for :</b><br/>\n";
            } else {
                 print "      <b>&nbsp;&nbsp;" , $numPassengers . " " ,
                      $seatType , " class tickets for :</b><br/>\n";
            }

            # Passengers
            print "      <center><table border=\"0\" width=\"85%\"><tr><td>\n";
            print join ("      <li><i>", @passList, "</i>\n");
            print "      </td></tr></table></center>\n";

            print "  </TD>\n";
  
            # Vertical dots ....
            print "  <TD width=\"5%\" >.<br/>.<br/>.<br/>.</TD>\n";

            # Invoice sent to:
            print "  <TD width=\"45%\" valign=top><b>Invoice sent to:</b><br/>\n";
            print "      <center>\n";
            print "      <Table width=\"80%\" cellspacing=\"0\" > <tr> <td>\n";
            print "          $firstName $lastName<br/>\n";
            print "          $address1<br/>\n";
            print "          $address2<br/>\n";
            print "          <br/>\n";

            # Total Charge
            print "          Total Charge: \$ $totalPrice <BR/> (CC: x-$creditCard)\n";
            print "      </td> </tr> </table>\n";
            print "      </center>\n";
            print "  </TD>\n";

            # Flight Details
            print "</TR>\n";
            print "<TR bgcolor=\"$bgcolor\">\n";
            print "  <TD COLSPAN=\"3\">\n";
            print "  <b>Flight Details:</b><BR/>";
            print "  <center>\n";
            
            # Flight TO
            print "  $outboundDate : ";
            printFlightDesc($outboundFlight);

            # Return Flight
            if ($returnFlight != 0) {
                 print "  $returnDate : ";
                 printFlightDesc($returnFlight);
            }
  
            print "  </center>\n";
            print "  </TD>\n";
            print "</TR>\n\n";
            print "<TR bgcolor=\"#EFF2F7\">\n",
                  "  <TD COLSPAN=\"4\">\n",
                  "  <hr/>\n",
                  "  </TD>\n",
                  "</TR>\n";

            # Increment TicketNum++
    		$ticketNum++;

	}

    if ($ticketNum > 1) {
		print "<TR>\n",
                  "   <TD align=\"center\" COLSPAN=\"4\">\n",
                  "   <b>A total of ", ($ticketNum - 1), " scheduled flights.</font></b>\n",
                  "   </TD>\n",
                  "</TR>\n";
		
		print "</TABLE>\n\n";
		print "<TABLE WIDTH=\"87%\" BORDER=\"0\" CELLSPACING=\"0\">\n",
                  "<TR>\n",
                  "<TD align=\"left\" width=\"50%\" >\n",
                  image_button(-name=>'removeFlights', 
                               -border=>'0', 
                               -src=>"$imageBase/cancelreservation.gif"),
                  "</TD>\n",
                  "<TD align=\"right\" width=\"50%\" >\n",
                  image_button(-name=>'removeAllFlights', 
 					 -border=>'0',
 			 		 -src=>"$imageBase/cancelallreservations.gif"),
                  "</TD>\n",
                  "</TABLE>\n\n";
      } else {
               $hdrstring =  "<center><H3>No flights have been reserved.</H3></center>\n";

               print $hdrstring;
      }
 	
 	# let's do 3 redirects through localredirect.pl
 	
  	if ($options{'MSO_Redirects'}) {
		print hidden(-name=>"iter", -value=>3),
				hidden(-name=>"dest", -value=>"itinerary.pl");
	}
	
 	print endform(), "\n\n</center>\n";
  	print p,p,p,"The Variables are: ",br,$dumpData if ($userID eq "vars");
  	print end_html();
}


#
# remove the checked flights.
# involves going through the current user file, creating a new user file with
# all the flights that should be kept, then copying the new file over the old one.
#

sub removeFlights {
	chdir("MTData");
  	chdir("users");
  	chdir($hash);
  	
  	@flightIDs = param('flightID'); 
  	$removeAll = param('removeAllFlights.x');

  	open (ACCOUNT, "<$userID");
	open (NEWACCOUNT, ">tmp$userID");
	
	# 5 default lines
	for ($i= 0; $i < $DEFAULTINFOLINES; $i++) {
		$line = <ACCOUNT>;
		print NEWACCOUNT $line;
	}
	
	$flightNum = 1;
	
	while (!(eof ACCOUNT)) {
		# need to parse the data in order to validate the flightID's
		$name = <ACCOUNT>;
		($firstName, $lastName) = split ";", $name;
		$add1 = <ACCOUNT>;
		$add2 = <ACCOUNT>;

  		($creditCard, $expDate) = split ";", <ACCOUNT>;
  		$creditCard = substr $creditCard, -4;  # last 4 digits of card
  		($numPassengers, $seatType, $seatPref) = split ";", <ACCOUNT>;
  		@passList = split ";", <ACCOUNT>;
  		($outboundFlight, $outboundPrice, $outboundDate) = split ";", <ACCOUNT>;
  		($returnFlight, $returnPrice, $returnDate) = split ";", <ACCOUNT>;
  		$totalPrice = ($outboundPrice + $returnPrice) * $numPassengers;

        # Compute valid flight identifier
  		$validID1 = "$creditCard$outboundFlight$outboundPrice";
		$validID2 = "$flightNum$returnFlight$totalPrice";
  		$validID1 = int ($validID1 / 27);
        $validID2 = int ($validID2 / 13);
        $validID  = "$validID1-$validID2" . substr($firstName,0,1) . substr($lastName,0,1);

		
			if ((param($flightNum) ne 'on') && (!($removeAll))) {
				print NEWACCOUNT $name, $add1, $add2;
				print NEWACCOUNT "$creditCard;$expDate";
				print NEWACCOUNT "$numPassengers;$seatType;$seatPref";
				print NEWACCOUNT join ";", @passList;
				print NEWACCOUNT "$outboundFlight;$outboundPrice;$outboundDate";
				print NEWACCOUNT "$returnFlight;$returnPrice;$returnDate";

			}
			
			if ($flightIDs[$flightNum-1] != $validID) {
				$badIDs = 1;
			}
			
		
		param($flightNum, '');
		$flightNum++;
	}

	close(ACCOUNT);
	close(NEWACCOUNT);
	
	if ($badIDs == 1) {
		unlink "tmp$userID";
		return 0;
	}
	else {
		rename "tmp$userID", "$userID";
		return 1;
	}
	
}

sub showError {
	printItineraryHeader();
    	print "<BR/><BR/><h1>&nbsp;&nbsp;<b>Itinerary</b></h1>\n<blockquote>";
   	print  "<P break>Unfortunately, we could not delete your entire itinerary ",
   			"because of a database synchronization error.  If you could please ",
   			"re-load your itinerary and try again, we would appreciate it.  Thank you ",
   			"for your patience.</blockquote>";
	
  	print p,p,p,"The Variables are: ",br,$dumpData if ($userID eq "vars");
   	
   	print end_html();

	
	
}

#
# Displays the standard header for the itinerary pages.
#
#
sub printItineraryHeader {
	print header(-expires=>'-1d'), start_html(-title=>'Flights List',
                         -bgcolor=>'#E0E7F1',);
	printCSS();
}

sub printCSS {
	print "<style>blockquote {font-family: tahoma; font-size : 10pt}";
	print "H1 {font-family: tahoma; font-size : 22pt; color: #993333}";
	print "small {font-family: tahoma; font-size : 8pt}";
	print "H3 {font-family: tahoma; font-size : 10pt; color: black}";
	print "TD {font-family: tahoma; font-size : 8pt; color: black}";
	print "</style>";
}